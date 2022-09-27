//
//  BSBacktraceLogger.m
//  BSBacktraceLogger
//
//  Created by 张星宇 on 16/8/27.
//  Copyright © 2016年 bestswifter. All rights reserved.
//

#import "BSBacktraceLogger.h"
#import <mach/mach.h>
#include <dlfcn.h>
#include <pthread.h>
#include <sys/types.h>
#include <limits.h>
#include <string.h>
#include <mach-o/dyld.h>
#include <mach-o/nlist.h>

#pragma -mark DEFINE MACRO FOR DIFFERENT CPU ARCHITECTURE
#if defined(__arm64__)
#define DETAG_INSTRUCTION_ADDRESS(A) ((A) & ~(3UL))
#define BS_THREAD_STATE_COUNT ARM_THREAD_STATE64_COUNT
#define BS_THREAD_STATE ARM_THREAD_STATE64
#define BS_FRAME_POINTER __fp
#define BS_STACK_POINTER __sp
#define BS_INSTRUCTION_ADDRESS __pc

#elif defined(__arm__)
#define DETAG_INSTRUCTION_ADDRESS(A) ((A) & ~(1UL))
#define BS_THREAD_STATE_COUNT ARM_THREAD_STATE_COUNT
#define BS_THREAD_STATE ARM_THREAD_STATE
#define BS_FRAME_POINTER __r[7]
#define BS_STACK_POINTER __sp
#define BS_INSTRUCTION_ADDRESS __pc

#elif defined(__x86_64__)
#define DETAG_INSTRUCTION_ADDRESS(A) (A)
#define BS_THREAD_STATE_COUNT x86_THREAD_STATE64_COUNT
#define BS_THREAD_STATE x86_THREAD_STATE64
#define BS_FRAME_POINTER __rbp
#define BS_STACK_POINTER __rsp
#define BS_INSTRUCTION_ADDRESS __rip

#elif defined(__i386__)
#define DETAG_INSTRUCTION_ADDRESS(A) (A)
#define BS_THREAD_STATE_COUNT x86_THREAD_STATE32_COUNT
#define BS_THREAD_STATE x86_THREAD_STATE32
#define BS_FRAME_POINTER __ebp
#define BS_STACK_POINTER __esp
#define BS_INSTRUCTION_ADDRESS __eip

#endif

#define CALL_INSTRUCTION_FROM_RETURN_ADDRESS(A) (DETAG_INSTRUCTION_ADDRESS((A)) - 1)

#if defined(__LP64__)
#define TRACE_FMT         "%-4d%-31s 0x%016lx %s + %lu"
#define POINTER_FMT       "0x%016lx"
#define POINTER_SHORT_FMT "0x%lx"
#define BS_NLIST struct nlist_64
#else
#define TRACE_FMT         "%-4d%-31s 0x%08lx %s + %lu"
#define POINTER_FMT       "0x%08lx"
#define POINTER_SHORT_FMT "0x%lx"
#define BS_NLIST struct nlist
#endif

typedef struct BSStackFrameEntry{
    const struct BSStackFrameEntry *const previous;
    const uintptr_t return_address;
} BSStackFrameEntry;

static mach_port_t main_thread_id;

@implementation BSBacktraceLogger

+ (void)load {
    main_thread_id = mach_thread_self();
}

#pragma -mark Implementation of interface
+ (NSString *)bs_backtraceOfNSThread:(NSThread *)thread {
    // 调用 bs_machThreadFromNSThread 函数把 thread 转换为 thread_t（实际是 typedef mach_port_t thread_t）类型的 Mach 线程，然后调用 _bs_backtraceOfThread 获取调用栈回溯字符串，
    // 这里并不是一个什么数据结构的转换过程，只是一个对应线程的查询：在当前 task 的所有线程中找到与指定 NSThread 对应的 Mach 线程。
    
    return _bs_backtraceOfThread(bs_machThreadFromNSThread(thread));
}

+ (NSString *)bs_backtraceOfCurrentThread {
    // 对 [NSThread currentThread] 当前线程进行调用栈回溯
    
    return [self bs_backtraceOfNSThread:[NSThread currentThread]];
}

+ (NSString *)bs_backtraceOfMainThread {
    // 对 [NSThread mainThread] 主线程进行调用栈回溯
    
    return [self bs_backtraceOfNSThread:[NSThread mainThread]];
}

+ (NSString *)bs_backtraceOfMachThread:(thread_t)machThread
{
    return _bs_backtraceOfThread(machThread);
}

+ (NSString *)bs_backtraceOfAllThread {
    // 记录当前所有线程的 port
    thread_act_array_t threads;
    
    // 记录当前线程的数量
    mach_msg_type_number_t thread_count = 0;
    
    // 当前的 task
    const task_t this_task = mach_task_self();
    
    // 获取当前所有线程和线程数量，分别记录在 threads 和 thread_count 中
    kern_return_t kr = task_threads(this_task, &threads, &thread_count);
    if(kr != KERN_SUCCESS) {
        return @"Fail to get information of all threads";
    }
    
    // 调用栈回溯字符串的开头拼接上线程数量字符串
    NSMutableString *resultString = [NSMutableString stringWithFormat:@"Call Backtrace of %u threads:\n", thread_count];
    
    // 然后循环对所有的线程进行调用栈回溯，把回溯的字符串拼接在 resultString 中
    for(int i = 0; i < thread_count; i++) {
        [resultString appendFormat:@"====%d\n", i];
        [resultString appendString:_bs_backtraceOfThread(threads[i])];
    }
    return [resultString copy];
}

#pragma mark get call backtrace of threadState
+ (NSString *)bs_backtraceOfThreadState:(_STRUCT_MCONTEXT )machineContext {
    return _bs_backtraceOfThreadState(machineContext);
}
/// wugl
NSString *_bs_backtraceOfThreadState(_STRUCT_MCONTEXT machineContext) {
    uintptr_t backtraceBuffer[50];
    int i = 0;
    NSMutableString *resultString = [[NSMutableString alloc] initWithFormat:@"Backtrace of Thread : \n\n"];
        
    const uintptr_t instructionAddress = bs_mach_instructionAddress(&machineContext);
    backtraceBuffer[i] = instructionAddress;
    ++i;
    
    uintptr_t linkRegister = bs_mach_linkRegister(&machineContext);
    if (linkRegister) {
        backtraceBuffer[i] = linkRegister;
        i++;
    }
    
    if(instructionAddress == 0) {
        return @"Fail to get instruction address";
    }
    
    BSStackFrameEntry frame = {0};
    const uintptr_t framePtr = bs_mach_framePointer(&machineContext);
    if(framePtr == 0 ||
       bs_mach_copyMem((void *)framePtr, &frame, sizeof(frame)) != KERN_SUCCESS) {
        return @"Fail to get frame pointer";
    }
    
    for(; i < 50; i++) {
        backtraceBuffer[i] = frame.return_address;
        if(backtraceBuffer[i] == 0 ||
           frame.previous == 0 ||
           bs_mach_copyMem(frame.previous, &frame, sizeof(frame)) != KERN_SUCCESS) {
            break;
        }
    }
    
    int backtraceLength = i;
    Dl_info symbolicated[backtraceLength];
    bs_symbolicate(backtraceBuffer, symbolicated, backtraceLength, 0);
    for (int i = 0; i < backtraceLength; ++i) {
        [resultString appendFormat:@"%@", bs_logBacktraceEntry(i, backtraceBuffer[i], &symbolicated[i])];
    }
    [resultString appendFormat:@"\n"];
    return [resultString copy];
}

#pragma -mark Get call backtrace of a mach_thread
NSString *_bs_backtraceOfThread(thread_t thread) {
    // 默认栈深度是 50
    uintptr_t backtraceBuffer[50];
    int i = 0;
    
    // 调用栈回溯字符串变量 resultString，默认开头都是 thread ID（port）
    NSMutableString *resultString = [[NSMutableString alloc] initWithFormat:@"Backtrace of Thread %u:\n", thread];
    
    /**
     #define _STRUCT_MCONTEXT _STRUCT_MCONTEXT64
     
     _STRUCT_MCONTEXT64
     {
         _STRUCT_X86_EXCEPTION_STATE64   __es; // 异常状态记录
         _STRUCT_X86_THREAD_STATE64      __ss; // 线程上下文（寄存器列表）
         _STRUCT_X86_FLOAT_STATE64       __fs; // 浮点寄存器
     };
     */
    
    // 针对不同平台的机器声明一个用来存储线程上下文的变量
    _STRUCT_MCONTEXT machineContext;
    
    // 1⃣️ 获取指定线程的上下文信息，如果获取失败的话直接返回错误描述
    if(!bs_fillThreadStateIntoMachineContext(thread, &machineContext)) {
        return [NSString stringWithFormat:@"Fail to get information about thread: %u", thread];
    }
    
    // 2⃣️ 获取 __rip 寄存器的值（对应 ARM 架构下 PC 寄存器的值）
    const uintptr_t instructionAddress = bs_mach_instructionAddress(&machineContext);
    
    // 把 PC 寄存器的值记录在回溯缓冲数组中...
    backtraceBuffer[i] = instructionAddress;
    ++i;
    
    // FP(x29) 栈底 SP 栈顶 PC 下一条指令 LR(x30) 函数返回后的下一个函数的第一条指令
    // x29(FP) 栈底寄存器 SP 栈顶寄存器 LR（x30）是当前函数返回后，下一个函数的第一条指令 PC 下一条指令
    // 3⃣️ 读取 LR 寄存器的值，只有 ARM 平台有，x86 平台返回 0
    uintptr_t linkRegister = bs_mach_linkRegister(&machineContext);
    if (linkRegister) {
        // 把 LR 寄存器的值记录在回溯缓冲数组中...
        backtraceBuffer[i] = linkRegister;
        i++;
    }
    
    // 如果 instructionAddress 为 0 的话，即获取 PC 寄存器的值为 0，则返回一个错误字符串，感觉这个判断应该放在上面获取后直接判断吧，没必要读了 LR 寄存器再判断吧！
    if(instructionAddress == 0) {
        return @"Fail to get instruction address";
    }
    
    
    // 创建一个栈帧节点
    BSStackFrameEntry frame = {0};
    
    // 4⃣️ 取得 FP 栈底寄存器的值
    const uintptr_t framePtr = bs_mach_framePointer(&machineContext);
    
    // 5⃣️ bs_mach_copyMem 函数内部对 vm_read_overwrite 函数进行封装。
    // 使用 vm_read_overwrite() 函数，从目标进程 "读取" 内存。
    // 注意，这个函数与 vm_read() 不同，应该并没有做实际的数据拷贝，而是将 [region.address ~ region.address + region.size] 范围对应的所有映射状态同步给了 [region_data ~ region_data + region.size]，对于 Resident 的部分，两个进程中不同的虚拟内存地址对应的应该是相同的物理内存地址。
 
    // 如果 framePtr 等于 0 或者以 framePtr 为起始地址，复制 sizeof(frame) 个长度的虚拟内存的数据到 frame 指针中去失败，则返回错误描述，
    // 这里 frame 变量是 struct BSStackFrameEntry 类型的结构体，它内部一个指针，一个无符号 long 变量，所以 sizeof(frame) 的值为 16，
    // 即这里的作用是把 FP 栈底寄存器的值和 SP 栈顶寄存器的值复制到 frame 中
    if(framePtr == 0 ||
       bs_mach_copyMem((void *)framePtr, &frame, sizeof(frame)) != KERN_SUCCESS) {
        return @"Fail to get frame pointer";
    }
    
    // 循环 50 次，沿着栈底指针构建一个链表，链表的每个节点都是每个调用帧的栈底指针，即前一个函数帧的起始地址
    for(; i < 50; i++) {
        backtraceBuffer[i] = frame.return_address;
        
        // 直到 FP 为 0，前一个 FP 指向 0，内存读取失败，跳出循环
        if(backtraceBuffer[i] == 0 ||
           frame.previous == 0 ||
           bs_mach_copyMem(frame.previous, &frame, sizeof(frame)) != KERN_SUCCESS) {
            break;
        }
    }
    
    // 准备一个值 i 的 backtraceLength 长度的 Dl_info 数组
    int backtraceLength = i;
    Dl_info symbolicated[backtraceLength];
    
    // 7⃣️ 查找 backtraceBuffer 数组中地址对应的符号信息
    bs_symbolicate(backtraceBuffer, symbolicated, backtraceLength, 0);
    
    // 遍历调用栈回溯中的函数字符串拼接在 resultString 字符串中
    for (int i = 0; i < backtraceLength; ++i) {
        
        // 8⃣️ 根据 `BsBacktraceLogger 0x10fa4359c -[ViewController bar] + 12` 这个格式，把调用栈的回溯字符串拼接在一起
        [resultString appendFormat:@"%@", bs_logBacktraceEntry(i, backtraceBuffer[i], &symbolicated[i])];
    }
    [resultString appendFormat:@"\n"];
    return [resultString copy];
}

#pragma -mark Convert NSThread to Mach thread

/// NSThread 转换为 thread_t 类型的 Mach 线程
/// @param nsthread NSThread 线程对象
thread_t bs_machThreadFromNSThread(NSThread *nsthread) {
    char name[256];
    
    // 用来存储当前 task 的线程数量
    mach_msg_type_number_t count;
    
    // 用来存储当前所有线程的 mach_port_t 的数组（typedef mach_port_t thread_t; mach_port_t 是 thread_t 的别名）
 
    // 这里我们按住 command 点击查看一下 thread_act_array_t 的实际类型：
    // 首先 `typedef thread_act_t *thread_act_array_t;` 看到 thread_act_array_t 是一个 thread_act_t 指针，
    // 然后 `typedef mach_port_t thread_act_t;` 即 list 实际就是一个 mach_port_t 数组，实际就是一个 thread_t 数组。
    thread_act_array_t list;
    
    // 调用 task_threads 函数根据当前的 task 来获取所有线程（线程端口），保存在 list 变量中，count 记录线程的总数量
 
    // mach_task_self() 表示获取当前的 Mach task，它的类型其实也是 mach_port_t，这里牵涉到 macOS 中 Mach 微内核用户态和内核态的一些的知识点。
    // mach_task_self() 获取当前 task，看到该函数返回的类型也是 mach_port_t：extern mach_port_t mach_task_self_;
    // #define mach_task_self() mach_task_self_
    task_threads(mach_task_self(), &list, &count);
    
    // 当前时间戳
    NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
    
    // 取出 nsthread 的 name 记录在 originName 中（大概率是空字符串，如果没有给 thread 设置 name 的话），然后取当前的时间戳作为 nsthread 的新名字
    NSString *originName = [nsthread name];
    
    // 这里除了把 nsthread 的名字设置为时间戳，也会把 nsthread 对应的 pthread_t 的名字设置为同一个值
    [nsthread setName:[NSString stringWithFormat:@"%f", currentTimestamp]];
    
    // 如果 nsthread 是主线程的话直接返回在 +load 函数中获取的主线程的 mach_port_t
    if ([nsthread isMainThread]) {
        // 这里直接把 mach_port_t 强制转换为了 thread_t，因为实际 `typedef mach_port_t thread_t;`，mach_port_t 就是 thread_t 的别名
        return (thread_t)main_thread_id;
    }
    
    // 遍历 list 数组中的 mach_port_t
    for (int i = 0; i < count; ++i) {
        
        // _Nullable pthread_t pthread_from_mach_thread_np(mach_port_t);
        // 调用 pthread_from_mach_thread_np 函数，从 mach_port_t 转换为 pthread_t，注意这里是 pthread_t 比上面的 thread_t 多了一个 p
        pthread_t pt = pthread_from_mach_thread_np(list[i]);
        
        // mach_port_t machThread = pthread_mach_thread_np(pthread_t)
        
        // 这里的再一次的 if ([nsthread isMainThread]) {} 判断，没看懂，上面不是有了一个判断了吗？
        // 如果是主线程的话，再次返回主线程对应的 mach_port_t
        if ([nsthread isMainThread]) {
            if (list[i] == main_thread_id) {
                return list[i];
            }
        }
        
        // 获取 pt 的名字，然后与 nsthread 进行比较，取得 nsthread 对应的 thread_t
        if (pt) {
            name[0] = '\0';
            
            // 获取 pthread_t 的名字，保存在 name char 数组中
            pthread_getname_np(pt, name, sizeof name);
            
            // strcmp 函数是 string compare（字符串比较）的缩写，用于比较两个字符串并根据比较结果返回整数。
            // 基本形式为 strcmp(str1,str2)，若 str1=str2，则返回零；若 str1<str2，则返回负数；若str1>str2，则返回正数。
            // 如果两者相等，表示找到了 nsthread 对应的 Mach 线程，然后把 nsthread 恢复原名，并返回 list[i]
            if (!strcmp(name, [nsthread name].UTF8String)) {
                [nsthread setName:originName];
                return list[i];
            }
        }
    }
    
    [nsthread setName:originName];
    return mach_thread_self();
}

#pragma -mark GenerateBacbsrackEnrty
NSString* bs_logBacktraceEntry(const int entryNum,
                               const uintptr_t address,
                               const Dl_info* const dlInfo) {
    char faddrBuff[20];
    char saddrBuff[20];
    
    const char* fname = bs_lastPathEntry(dlInfo->dli_fname);
    if(fname == NULL) {
        sprintf(faddrBuff, POINTER_FMT, (uintptr_t)dlInfo->dli_fbase);
        fname = faddrBuff;
    }
    
    uintptr_t offset = address - (uintptr_t)dlInfo->dli_saddr;
    const char* sname = dlInfo->dli_sname;
    if(sname == NULL) {
        sprintf(saddrBuff, POINTER_SHORT_FMT, (uintptr_t)dlInfo->dli_fbase);
        sname = saddrBuff;
        offset = address - (uintptr_t)dlInfo->dli_fbase;
    }
    return [NSString stringWithFormat:@"%-30s  0x%08" PRIxPTR " %s + %lu\n" ,fname, (uintptr_t)address, sname, offset];
}

const char* bs_lastPathEntry(const char* const path) {
    if(path == NULL) {
        return NULL;
    }
    
    char* lastFile = strrchr(path, '/');
    return lastFile == NULL ? path : lastFile + 1;
}

#pragma -mark HandleMachineContext

/**
  获取 thread 的状态赋值到 machineContext 参数（实际只给 &machineContext->__ss 赋值），bool 类型返回值表示是否获取成功/失败，&machineContext->__ss 结构体在上面也已经看过了，是记录寄存器列表的一个结构体。
 */
bool bs_fillThreadStateIntoMachineContext(thread_t thread, _STRUCT_MCONTEXT *machineContext) {
    mach_msg_type_number_t state_count = BS_THREAD_STATE_COUNT;
    
    // #define BS_THREAD_STATE_COUNT x86_THREAD_STATE64_COUNT
    // typedef _STRUCT_X86_THREAD_STATE64 x86_thread_state64_t;
    // #define x86_THREAD_STATE64_COUNT ((mach_msg_type_number_t) ( sizeof (x86_thread_state64_t) / sizeof (int) ))
 
    // #define BS_THREAD_STATE x86_THREAD_STATE64
    // x86_THREAD_STATE64 值为 4
    // state_count 值为 42
    // 42 * 4 和 21 * 8 都等于 168
 
    // 获取指定 thread 的上下文，并赋值在 &machineContext->__ss 参数中（寄存器列表）
    
    kern_return_t kr = thread_get_state(thread, BS_THREAD_STATE, (thread_state_t)&machineContext->__ss, &state_count);
    return (kr == KERN_SUCCESS);
}

// 获取栈底寄存器的值
uintptr_t bs_mach_framePointer(mcontext_t const machineContext){
    return machineContext->__ss.BS_FRAME_POINTER;
}

// 获取栈顶寄存器的值
uintptr_t bs_mach_stackPointer(mcontext_t const machineContext){
    return machineContext->__ss.BS_STACK_POINTER;
}

// 获取 x86 平台下 IP 寄存器的值，对应 ARM 架构下 PC 寄存器的值
uintptr_t bs_mach_instructionAddress(mcontext_t const machineContext){
    return machineContext->__ss.BS_INSTRUCTION_ADDRESS;
}

// 读取 LR 寄存器的值，LR 是当前函数结束后，下一个函数的第一条指令。x86 平台没有这个寄存器，只有 ARM 平台才有
uintptr_t bs_mach_linkRegister(mcontext_t const machineContext){
#if defined(__i386__) || defined(__x86_64__)
    return 0;
#else
    return machineContext->__ss.__lr;
#endif
}

// 复制当前 task 指定位置的指定长度的虚拟内存空间中的内容，主要用于复制寄存器空间中的值
kern_return_t bs_mach_copyMem(const void *const src, void *const dst, const size_t numBytes){
    vm_size_t bytesCopied = 0;
    return vm_read_overwrite(mach_task_self(), (vm_address_t)src, (vm_size_t)numBytes, (vm_address_t)dst, &bytesCopied);
}

#pragma -mark Symbolicate

/**
  bs_symbolicate 符号化，把指定地址进行符号化，即找到指定地址所对应的符号信息。

  这里我们首先看一下它的参数：const uintptr_t* const backtraceBuffer 这个是栈底指针的数组，也是每个函数调用栈起始地址的指针（这句话有无，是lr地址数组才对），我们就是根据这个指针去 Image 中查找最接近的符号。Dl_info* const symbolsBuffer 是一个 Dl_info 数组（Dl_info symbolicated[backtraceLength]）：
 */
void bs_symbolicate(const uintptr_t* const backtraceBuffer,
                    Dl_info* const symbolsBuffer,
                    const int numEntries,
                    const int skippedEntries){
    int i = 0;
    
    // _bs_backtraceOfThread 函数内调用 bs_symbolicate 函数时，skippedEntries 传的到都是 0 可忽略
    if(!skippedEntries && i < numEntries) {
        
        // 查找指定地址 address 最接近的符号的信息
        bs_dladdr(backtraceBuffer[i], &symbolsBuffer[i]);
        i++;
    }
    
    // 然后遍历查找指定地址 address 最接近的符号的信息，
    for(; i < numEntries; i++) {
        
        // CALL_INSTRUCTION_FROM_RETURN_ADDRESS(backtraceBuffer[i]) 去掉地址最后两位的地址签名，并数组偏移 1 个元素
        bs_dladdr(CALL_INSTRUCTION_FROM_RETURN_ADDRESS(backtraceBuffer[i]), &symbolsBuffer[i]);
    }
}

// 查找指定地址 address 最接近的符号的信息
bool bs_dladdr(const uintptr_t address, Dl_info* const info) {
    info->dli_fname = NULL;
    info->dli_fbase = NULL;
    info->dli_sname = NULL;
    info->dli_saddr = NULL;
    
    // 判断一个指定地址是否在当前已经加载的某个 Image 中并返回该 Image 在 _dyld_image_count 数值中的索引，即取得指定地址在某个 image 中并返回此 image 的索引
    const uint32_t idx = bs_imageIndexContainingAddress(address);
    
    // 如果返回 UINT_MAX 表示在当前已经加载的 Image 镜像中找不到 address 地址
    if(idx == UINT_MAX) {
        return false;
    }
    
    // 取得此 Image 镜像的 header 地址
    const struct mach_header* header = _dyld_get_image_header(idx);
    
    // 取得此 Image 内存地址的 slide 值
    const uintptr_t imageVMAddrSlide = (uintptr_t)_dyld_get_image_vmaddr_slide(idx);
    
    // 取得此 指定 内存地址 在 Image 的偏移地址
    const uintptr_t addressWithSlide = address - imageVMAddrSlide;
    
    // 取得 Image 在当前可执行文件中的虚拟地址的基地址然后加上 Slide
    const uintptr_t segmentBase = bs_segmentBaseOfImageIndex(idx) + imageVMAddrSlide;
    if(segmentBase == 0) {
        return false;
    }
    
    // Image 的名字赋值给 dli_fname，实际的值是 Image 的完整路径
    info->dli_fname = _dyld_get_image_name(idx);
    
    // Base address of shared object
    info->dli_fbase = (void*)header;
    
    // Find symbol tables and get whichever symbol is closest to the address.
    // 查找符号表并获取最接近地址的符号
    // #define BS_NLIST struct nlist_64
    // 符号表中的每个元素正是这个 struct nlist_64/nlist 结构体
    const BS_NLIST* bestMatch = NULL;
    
    // 无符号 long 最大值
    uintptr_t bestDistance = ULONG_MAX;
    
    // 针对 64 位和非 64 位的可执行文件，内部的 +1 是跳过 __PAGEZERO 段（有误）
    uintptr_t cmdPtr = bs_firstCmdAfterHeader(header);
    if(cmdPtr == 0) {
        return false;
    }
    
    // 遍历 Image 的 Load Command
    for(uint32_t iCmd = 0; iCmd < header->ncmds; iCmd++) {
        const struct load_command* loadCmd = (struct load_command*)cmdPtr;
        
        // 找到 LC_SYMTAB 段，
        if(loadCmd->cmd == LC_SYMTAB) {
            
            // 因为 loadCmd 是 LC_SYMTAB 类型，所以这里可直接把 cmdPtr 强制转换为 struct symtab_command * 指针
            const struct symtab_command* symtabCmd = (struct symtab_command*)cmdPtr;
            
            // 直接基地址 + symbol table 偏移，取得符号表的首地址，且符号表中正是 struct nlist/nlist_64 类型数组，所以这里直接强转为 BS_NLIST 指针
            const BS_NLIST* symbolTable = (BS_NLIST*)(segmentBase + symtabCmd->symoff);
            
            // 然后直接基地址 + string table 偏移，取得保存符号名字符串的表的起始地址
            const uintptr_t stringTable = segmentBase + symtabCmd->stroff;
            
            // 然后对符号表中的符号进行遍历，找到最接近 address 的符号，保存在 bestMatch 变量中，
            for(uint32_t iSym = 0; iSym < symtabCmd->nsyms; iSym++) {
                
                // 这是 64 位体系结构的符号表条目结构。
                // 如果 n_value 为 0，则该符号引用外部对象
                if(symbolTable[iSym].n_value != 0) {
                    
                    // 取得当前符号的地址
                    uintptr_t symbolBase = symbolTable[iSym].n_value;
                    
                    // 这里没太理解，用 addressWithSlide 减去 symbolBase，理论上 addressWithSlide 的值应该会小于 symbolBase（有误），
                    // addressWithSlide：指定地址在文件中的偏移（不带slider）、symbolBase：当前符号在文件中的偏移（不带slider）
                    // 硬减的话会得到一个负值，然后因为 currentDistance 是一个无符号 long，
                    // 所以这里 currentDistance 的值是减法溢出后转换为无符号 long，
                    // 这里遍历符号，每次记录当前符号和指定地址的距离，记录下来
                    /**
                     在执行代码区域，每个符号之间是连续的，而且符号会全部保存在符号表中，
                     那么我们可以遍历符号表，查找到小于LR位置，并且距离LR最近的一个符号，
                     那么我们就可以认为我们的函数跳转发生在该函数内部
                     */
                    uintptr_t currentDistance = addressWithSlide - symbolBase;
                    
                    // 然后记录到一个最接近指定地址的符号（每遇到一个最近的距离值就更新一下 bestDistance 的值）
                    if((addressWithSlide >= symbolBase) &&
                       (currentDistance <= bestDistance)) {
                        bestMatch = symbolTable + iSym;
                        bestDistance = currentDistance;
                    }
                }
            }
            
            // 找到 bestMatch 时，记录下当前 Image 的：
            if(bestMatch != NULL) {
                
                // dli_saddr 最近符号的地址
                info->dli_saddr = (void*)(bestMatch->n_value + imageVMAddrSlide);
                
                // dli_sname 最近符号的名称
                info->dli_sname = (char*)((intptr_t)stringTable + (intptr_t)bestMatch->n_un.n_strx);
                if(*info->dli_sname == '_') {
                    info->dli_sname++;
                }
                
                // This happens if all symbols have been stripped.
                // 如果所有符号都已被剥离，则会发生这种情况。
                if(info->dli_saddr == info->dli_fbase && bestMatch->n_type == 3) {
                    info->dli_sname = NULL;
                }
                break;
            }
        }
        
        // 偏移到下一个 Load Command
        cmdPtr += loadCmd->cmdsize;
    }
    return true;
}

/// 针对 64 位和非 64 位的可执行文件，这里的 +1 是跳过 __PAGEZERO 段（这里有误：+1是偏移header长度，因为第一个segment紧跟着header）
/// @param header Image header
uintptr_t bs_firstCmdAfterHeader(const struct mach_header* const header) {
    switch(header->magic) {
        case MH_MAGIC:
        case MH_CIGAM:
            return (uintptr_t)(header + 1);
        case MH_MAGIC_64:
        case MH_CIGAM_64:
            return (uintptr_t)(((struct mach_header_64*)header) + 1);
        default:
            return 0;  // Header is corrupt
    }
}

/// 判断一个指定地址是否在当前已经加载的某个 Image 中并返回该 Image 在 _dyld_image_count 数值中的索引，即取得指定地址在某个 image 中并返回此 image 的索引
/// @param address 指定地址
uint32_t bs_imageIndexContainingAddress(const uintptr_t address) {
    // 当前 dyld 加载的 Image 镜像的数量
    const uint32_t imageCount = _dyld_image_count();
    
    // image header 的指针
    const struct mach_header* header = 0;
    
    // 开始遍历这些 Image 镜像
    for(uint32_t iImg = 0; iImg < imageCount; iImg++) {
        
        // 取得当前这个 image 的 header 指针
        header = _dyld_get_image_header(iImg);
        
        if(header != NULL) {
            // Look for a segment command with this address within its range.
            // address 减去 image 的 slide 随机值，取得它的基地址
            uintptr_t addressWSlide = address - (uintptr_t)_dyld_get_image_vmaddr_slide(iImg);
            
            // 当前 image 的第一个段的地址（segment紧跟在HEADER后面）
            uintptr_t cmdPtr = bs_firstCmdAfterHeader(header);
            if(cmdPtr == 0) {
                continue;
            }
            
            // 然后再开始遍历这个 Image 中的所有 Load Command
            for(uint32_t iCmd = 0; iCmd < header->ncmds; iCmd++) {
                
                // 强转为 struct load_command * 指针
                const struct load_command* loadCmd = (struct load_command*)cmdPtr;
                
                // 然后仅需要遍历 LC_SEGMENT/LC_SEGMENT_64 类型的段
                if(loadCmd->cmd == LC_SEGMENT) {
                    
                    // 强转为 struct segment_command * 指针
                    const struct segment_command* segCmd = (struct segment_command*)cmdPtr;
                    
                    // 然后判断 addressWSlide 是否在这个段的虚拟地址的范围内
                    if(addressWSlide >= segCmd->vmaddr &&
                       addressWSlide < segCmd->vmaddr + segCmd->vmsize) {
                        // 如果在的话直接返回此 Image 的索引
                        return iImg;
                    }
                }
                else if(loadCmd->cmd == LC_SEGMENT_64) {
                    
                    // 强转为 struct segment_command_64 * 指针
                    const struct segment_command_64* segCmd = (struct segment_command_64*)cmdPtr;
                    
                    // 然后判断 addressWSlide 是否在这个段的虚拟地址的范围内
                    if(addressWSlide >= segCmd->vmaddr &&
                       addressWSlide < segCmd->vmaddr + segCmd->vmsize) {
                        
                        // 如果在的话直接返回此 Image 的索引
                        return iImg;
                    }
                }
                
                // 偏移当前 cmd 的宽度，到下一个 Load Command
                cmdPtr += loadCmd->cmdsize;
            }
        }
    }
    
    // 如果未找到的话，就返回无符号 Int 的最大值
    return UINT_MAX;
}

/// 取得指定索引的 Image 的 __LINKEDIT 段的虚拟地址减去 fileoff（file offset of this segment），得出此 Image 的虚拟基地址，
/// 这里为什么一定要用 __LINKEDIT 段没看明白，我使用 MachOView 查看了一下可执行文件，如下，看到使用其它几个段的 VM Address 减去 File Offset 得到的值是一样的，都是 4294967296
///
/// __TEXT: VM Address: 4294967296，File Offset: 0
/// __DATA_CONST: VM Address: 4295000064，File Offset: 32768 => 4295000064 - 32768 = 4294967296
/// __DATA: VM Address: 4295016448，File Offset: 49152 => 4295016448 - 49152 = 4294967296
/// __LINKEDIT: VM Address: 4295032832，File Offset: 65536 => 4295032832 - 65536 = 4294967296
///
/// @param idx image 索引
uintptr_t bs_segmentBaseOfImageIndex(const uint32_t idx) {
    const struct mach_header* header = _dyld_get_image_header(idx);
    
    // 取得 image 的第一个段(撇掉 __PAGEZERO 段)的地址，并把 struct mach_header_64 * 指针强转为了 uintptr_t（无符号 long）
    uintptr_t cmdPtr = bs_firstCmdAfterHeader(header);
    if(cmdPtr == 0) {
        return 0;
    }
    
    // 遍历所有的 Load Command
    for(uint32_t i = 0;i < header->ncmds; i++) {
        const struct load_command* loadCmd = (struct load_command*)cmdPtr;
        
        // 仅排查类型是 LC_SEGMENT 和 LC_SEGMENT_64 类型的 Load Command，并找到 __LINKEDIT 名字的段，计算出虚拟基地址并返回
        if(loadCmd->cmd == LC_SEGMENT) {
            
            // 取得段名是 __LINKEDIT 的段的虚拟基地址
            // 把地址强转为 struct segment_command * 指针
            const struct segment_command* segmentCmd = (struct segment_command*)cmdPtr;
            if(strcmp(segmentCmd->segname, SEG_LINKEDIT) == 0) {
                return segmentCmd->vmaddr - segmentCmd->fileoff;
            }
        }
        else if(loadCmd->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* segmentCmd = (struct segment_command_64*)cmdPtr;
            
            // 取得段名是 __LINKEDIT 的段的虚拟基地址
            if(strcmp(segmentCmd->segname, SEG_LINKEDIT) == 0) {
                return (uintptr_t)(segmentCmd->vmaddr - segmentCmd->fileoff);
            }
        }
        
        // 根据当前段的大小宽度：cmdsize 偏移到下一个段
        cmdPtr += loadCmd->cmdsize;
    }
    return 0;
}

@end
