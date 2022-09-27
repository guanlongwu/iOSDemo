//
//  GLCrashMachExceptionHandler.m
//  YYTool
//
//  Created by wugl on 2022/8/25.
//

#import "GLCrashMachExceptionHandler.h"
#import <pthread.h>
#import <mach/mach_init.h>
#import <mach/mach_port.h>
#import <mach/task.h>
#import <mach/message.h>
#import <mach/thread_act.h>
#import <mach/host_priv.h>
#import "BSBacktraceLogger.h"

/// 注册捕获异常的端口
// 自定义端口号
mach_port_name_t myExceptionPort = 10086;

@implementation GLCrashMachExceptionHandler

+ (void)registerHandler
{
    kern_return_t rc = 0;
    
    // 设置 Mach 异常的种类
    exception_mask_t excMask = EXC_MASK_BAD_ACCESS |
    EXC_MASK_BAD_INSTRUCTION |
    EXC_MASK_ARITHMETIC |
    EXC_MASK_SOFTWARE |
    EXC_MASK_BREAKPOINT;
    
    // 用自定义端口号初始化一个异常端口（端口用于 接收 异常）
    rc = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &myExceptionPort);
    if (rc != KERN_SUCCESS) {
        fprintf(stderr, "------->Fail to allocate exception port\\\\\\\\n");
        return;
    }
    
    // 向端口插入发送权限 （这时候端口既有接收，也有发送功能）
    rc = mach_port_insert_right(mach_task_self(), myExceptionPort, myExceptionPort, MACH_MSG_TYPE_MAKE_SEND);
    if (rc != KERN_SUCCESS) {
        fprintf(stderr, "-------->Fail to insert right");
        return;
    }
        
    // 设置内核接收 Mach 异常消息的 thread Port
//    thread_set_exception_ports(mach_thread_self(), excMask, myExceptionPort, EXCEPTION_DEFAULT, MACHINE_THREAD_STATE);
    rc = task_set_exception_ports(mach_task_self(), excMask, myExceptionPort, EXCEPTION_DEFAULT, MACHINE_THREAD_STATE);
//    host_set_exception_ports(host_priv_t host_priv, exception_mask_t exception_mask, mach_port_t new_port, exception_behavior_t behavior, thread_state_flavor_t new_flavor)
    if (rc != KERN_SUCCESS) {
        fprintf(stderr, "-------->Fail to  set exception\\\\\\\\n");
        return;
    }
        
    // 新建一个监听线程处理异常消息（内部循环等待异常消息）
    pthread_t thread;
    pthread_create(&thread, NULL, exc_handler, NULL);
}

/// 接收异常消息
static void *exc_handler(void *ignored)
{
    // 结果
    mach_msg_return_t rc;
    // 内核将发送给我们的异常消息的格式，参考 ux_handler() [bsd / uxkern / ux_exception.c] 中对异常消息的定义
    typedef struct {
        mach_msg_header_t Head;
        // start of the kernel processed data
        mach_msg_body_t msgh_body;
        mach_msg_port_descriptor_t thread;
        mach_msg_port_descriptor_t task;
        // end of the kernel processed data
        NDR_record_t NDR;
        exception_type_t exception;
        mach_msg_type_number_t codeCnt;
        integer_t code[2];
        int flavor;
        mach_msg_type_number_t old_stateCnt;
        natural_t old_state[144];
    } exc_msg_t;
    
    // 消息处理循环，这里的死循环不会有问题，因为 exc_handler 函数运行在一个独立的子线程中，而且 mach_msg 函数也是会阻塞的。
    for (;;) {
        exc_msg_t exc;
        
        // 这里会阻塞，直到接收到 exception message，或者线程被中断
        rc = mach_msg(&exc.Head, MACH_RCV_MSG | MACH_RCV_LARGE, 0, sizeof(exc_msg_t), myExceptionPort, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
        if (rc != MACH_MSG_SUCCESS) {
            //
            break;
        };
        
        NSLog(@"\n\n==== 🍀🍀🍀 uncaught Exception of type: Mach 🍀🍀🍀 ====\n\n");
        
        // 打印异常消息
        NSLog(@"\n🍀 CatchMACHExceptions %d.\n\n 🍀Exception : %d\n\n 🍀Flavor: %d.\n\n 🍀Code %d/%d.\n\n 🍀State count is %d\n\n", exc.Head.msgh_id, exc.exception, exc.flavor, exc.code[0], exc.code[1], exc.old_stateCnt);
        
        NSLog(@"\n\n🍀 😁 signalNameForMachException. exception:%d, signalName:%@\n\n", exc.exception, signalNameForMachException(exc.exception, exc.code[0]));
        
        
        mach_msg_port_descriptor_t thread = exc.thread;
        thread_t machThread = thread.name;
        NSLog(@"\n\n\n❤️ 🐒⭐️❤️ [mach exception] backtrace: \n\n %@ \n\n", [BSBacktraceLogger bs_backtraceOfMachThread:machThread]);
        
        // 定义转发出去的消息类型
        struct rep_msg {
            mach_msg_header_t Head;
            NDR_record_t NDR;
            kern_return_t RetCode;
        } rep_msg;
        
        rep_msg.Head = exc.Head;
        rep_msg.NDR = exc.NDR;
        rep_msg.RetCode = KERN_FAILURE;
        
        kern_return_t result;
        if (rc == MACH_MSG_SUCCESS) {
            // 将异常消息再转发出去
            result = mach_msg(&rep_msg.Head, MACH_SEND_MSG, sizeof(rep_msg), 0, MACH_PORT_NULL, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
        }
    }
    
    return NULL;
}

#define EXC_UNIX_BAD_SYSCALL 0x10000 /* SIGSYS */
#define EXC_UNIX_BAD_PIPE    0x10001 /* SIGPIPE */
#define EXC_UNIX_ABORT       0x10002 /* SIGABRT */
static NSString* signalNameForMachException(exception_type_t exception, mach_exception_code_t code)
{
    switch(exception)
    {
        case EXC_ARITHMETIC:
            return @"SIGFPE";
        case EXC_BAD_ACCESS:
            return code == KERN_INVALID_ADDRESS ? @"SIGSEGV" : @"SIGBUS";
        case EXC_BAD_INSTRUCTION:
            return @"SIGILL";
        case EXC_BREAKPOINT:
            return @"SIGTRAP";
        case EXC_EMULATION:
            return @"SIGEMT";
        case EXC_SOFTWARE:
        {
            switch (code)
            {
                case EXC_UNIX_BAD_SYSCALL:
                    return @"SIGSYS";
                case EXC_UNIX_BAD_PIPE:
                    return @"SIGPIPE";
                case EXC_UNIX_ABORT:
                    return @"SIGABRT";
                case EXC_SOFT_SIGNAL:
                    return @"SIGKILL";
            }
            break;
        }
    }
    return @"Unknown signal";
}


@end
