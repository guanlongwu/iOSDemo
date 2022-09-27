//
//  GLCrashSignalExceptionHandler.m
//  YYTool
//
//  Created by wugl on 2022/8/19.
//

#import "GLCrashSignalExceptionHandler.h"
#import <execinfo.h>
//#import "NWCrashTool.h"
#import "BSBacktraceLogger.h"

typedef void(*SignalHandler)(int signal, siginfo_t *info, void *context);
 
static SignalHandler previousABRTSignalHandler = NULL;
static SignalHandler previousBUSSignalHandler = NULL;
static SignalHandler previousFPESignalHandler = NULL;
static SignalHandler previousILLSignalHandler = NULL;
static SignalHandler previousPIPESignalHandler = NULL;
static SignalHandler previousSEGVSignalHandler = NULL;
static SignalHandler previousSYSSignalHandler = NULL;
static SignalHandler previousTRAPSignalHandler = NULL;
 
@implementation GLCrashSignalExceptionHandler
 
+ (void)registerHandler {
    // 将先前别人注册的handler取出并备份
    [self backupOriginalHandler];
    
    [self signalRegister];
}
 
+ (void)backupOriginalHandler {
    struct sigaction old_action_abrt;
    sigaction(SIGABRT, NULL, &old_action_abrt);
    if (old_action_abrt.sa_sigaction) {
        previousABRTSignalHandler = old_action_abrt.sa_sigaction;
    }
    
    struct sigaction old_action_bus;
    sigaction(SIGBUS, NULL, &old_action_bus);
    if (old_action_bus.sa_sigaction) {
        previousBUSSignalHandler = old_action_bus.sa_sigaction;
    }
    
    struct sigaction old_action_fpe;
    sigaction(SIGFPE, NULL, &old_action_fpe);
    if (old_action_fpe.sa_sigaction) {
        previousFPESignalHandler = old_action_fpe.sa_sigaction;
    }
    
    struct sigaction old_action_ill;
    sigaction(SIGILL, NULL, &old_action_ill);
    if (old_action_ill.sa_sigaction) {
        previousILLSignalHandler = old_action_ill.sa_sigaction;
    }
    
    struct sigaction old_action_pipe;
    sigaction(SIGPIPE, NULL, &old_action_pipe);
    if (old_action_pipe.sa_sigaction) {
        previousPIPESignalHandler = old_action_pipe.sa_sigaction;
    }
    
    struct sigaction old_action_segv;
    sigaction(SIGSEGV, NULL, &old_action_segv);
    if (old_action_segv.sa_sigaction) {
        previousSEGVSignalHandler = old_action_segv.sa_sigaction;
    }
    
    struct sigaction old_action_sys;
    sigaction(SIGSYS, NULL, &old_action_sys);
    if (old_action_sys.sa_sigaction) {
        previousSYSSignalHandler = old_action_sys.sa_sigaction;
    }
    
    struct sigaction old_action_trap;
    sigaction(SIGTRAP, NULL, &old_action_trap);
    if (old_action_trap.sa_sigaction) {
        previousTRAPSignalHandler = old_action_trap.sa_sigaction;
    }
}
 
+ (void)signalRegister {
    NWSignalRegister(SIGABRT);
    NWSignalRegister(SIGBUS);
    NWSignalRegister(SIGFPE);
    NWSignalRegister(SIGILL);
    NWSignalRegister(SIGPIPE);
    NWSignalRegister(SIGSEGV);
    NWSignalRegister(SIGSYS);
    NWSignalRegister(SIGTRAP);
}
 
#pragma mark - Private
 
#pragma mark Register Signal
 
static void NWSignalRegister(int signal) {
    struct sigaction action;
    action.sa_sigaction = NWSignalHandler;
    action.sa_flags = SA_NODEFER | SA_SIGINFO;
    sigemptyset(&action.sa_mask);
    sigaction(signal, &action, 0);
}
 
#pragma mark SignalCrash Handler
 
static void NWSignalHandler(int signal, siginfo_t* info, void* context) {
    NSMutableString *mstr = [[NSMutableString alloc] init];
    // 这里过滤掉第一行日志
    // 因为注册了信号崩溃回调方法，系统会来调用，将记录在调用堆栈上，因此此行日志需要过滤掉
    for (NSUInteger index = 1; index < NSThread.callStackSymbols.count; index++) {
        NSString *str = [NSThread.callStackSymbols objectAtIndex:index];
        [mstr appendString:[str stringByAppendingString:@"\n"]];
    }
    
    NSLog(@"\n\n==== ☀️☀️☀️ uncaught Exception of type: Signal ☀️☀️☀️ ====\n\n");
    
    NSLog(@"\n☀️ Signal Exception:\n%@", [NSString stringWithFormat:@"☀️ Signal %@ was raised.\n\n", signalName(signal)]);
        
    NSLog(@"\n☀️ ❎  [signal exception] Call Stack:\n\n%@", mstr);
    
    NSLog(@"\n☀️ threadInfo:\n%@\n\n", [[NSThread currentThread] description]);
    
    NSLog(@"\n\n====\n\n");
    
    /// 这种方式获取的堆栈不准
    NSLog(@"\n\n\n 🐒⭐️🍠☀️ ❌ [signal exception] backtrace: \n\n %@ \n\n", [BSBacktraceLogger bs_backtraceOfCurrentThread]);
    
    /// 下面这种方式获取的方式才能准
    _STRUCT_MCONTEXT machineContext;
    //直接获取崩溃时的线程执行状态
    _STRUCT_MCONTEXT *sourceContext = ((ucontext64_t *)context)->uc_mcontext64;
    memcpy(&machineContext, sourceContext, sizeof(machineContext));
    NSLog(@"\n\n\n ❤️🐒⭐️🍠☀️❤️ ✅ [signal exception] backtrace: \n\n %@ \n\n", [BSBacktraceLogger bs_backtraceOfThreadState:machineContext]);
    
    
    
    // 保存崩溃日志到沙盒cache目录
//    [NWCrashTool saveCrashLog:[NSString stringWithString:mstr] fileName:@"Crash(Signal)"];
    
    NWClearSignalRegister();
    
    // 调用之前崩溃的回调函数
    // 在自己handler处理完后自觉把别人的handler注册回去，规规矩矩的传递
    previousSignalHandler(signal, info, context);
    
    kill(getpid(), SIGKILL);
}
 
#pragma mark Signal To Name
 
static NSString *signalName(int signal) {
    NSString *signalName;
    switch (signal) {
        case SIGABRT:
            signalName = @"SIGABRT";
            break;
        case SIGBUS:
            signalName = @"SIGBUS";
            break;
        case SIGFPE:
            signalName = @"SIGFPE";
            break;
        case SIGILL:
            signalName = @"SIGILL";
            break;
        case SIGPIPE:
            signalName = @"SIGPIPE";
            break;
        case SIGSEGV:
            signalName = @"SIGSEGV";
            break;
        case SIGSYS:
            signalName = @"SIGSYS";
            break;
        case SIGTRAP:
            signalName = @"SIGTRAP";
            break;
        default:
            break;
    }
    return signalName;
}
 
#pragma mark Previous Signal
 
static void previousSignalHandler(int signal, siginfo_t *info, void *context) {
    SignalHandler previousSignalHandler = NULL;
    switch (signal) {
        case SIGABRT:
            previousSignalHandler = previousABRTSignalHandler;
            break;
        case SIGBUS:
            previousSignalHandler = previousBUSSignalHandler;
            break;
        case SIGFPE:
            previousSignalHandler = previousFPESignalHandler;
            break;
        case SIGILL:
            previousSignalHandler = previousILLSignalHandler;
            break;
        case SIGPIPE:
            previousSignalHandler = previousPIPESignalHandler;
            break;
        case SIGSEGV:
            previousSignalHandler = previousSEGVSignalHandler;
            break;
        case SIGSYS:
            previousSignalHandler = previousSYSSignalHandler;
            break;
        case SIGTRAP:
            previousSignalHandler = previousTRAPSignalHandler;
            break;
        default:
            break;
    }
    
    if (previousSignalHandler) {
        previousSignalHandler(signal, info, context);
    }
}
 
#pragma mark Clear
 
static void NWClearSignalRegister() {
    signal(SIGSEGV,SIG_DFL);
    signal(SIGFPE,SIG_DFL);
    signal(SIGBUS,SIG_DFL);
    signal(SIGTRAP,SIG_DFL);
    signal(SIGABRT,SIG_DFL);
    signal(SIGILL,SIG_DFL);
    signal(SIGPIPE,SIG_DFL);
    signal(SIGSYS,SIG_DFL);
}

#pragma mark - exception code 和 signal的转换

static
void ux_exception(
        int exception,
        mach_exception_code_t code,
        mach_exception_subcode_t subcode,
        int *ux_signal,
        mach_exception_code_t *ux_code)
{
    /*
     *  Try machine-dependent translation first.
     */
//    if (machine_exception(exception, code, subcode, ux_signal, ux_code))
//    return;
    
    switch(exception) {

    case EXC_BAD_ACCESS:
        if (code == KERN_INVALID_ADDRESS)
            *ux_signal = SIGSEGV;
        else
            *ux_signal = SIGBUS;
        break;

    case EXC_BAD_INSTRUCTION:
        *ux_signal = SIGILL;
        break;

    case EXC_ARITHMETIC:
        *ux_signal = SIGFPE;
        break;

    case EXC_EMULATION:
        *ux_signal = SIGEMT;
        break;

    case EXC_SOFTWARE:
        switch (code) {

//            case EXC_UNIX_BAD_SYSCALL:
//                *ux_signal = SIGSYS;
//                break;
//            case EXC_UNIX_BAD_PIPE:
//                *ux_signal = SIGPIPE;
//                break;
//            case EXC_UNIX_ABORT:
//                *ux_signal = SIGABRT;
//                break;
            case EXC_SOFT_SIGNAL:
                *ux_signal = SIGKILL;
                break;
        }
        break;

    case EXC_BREAKPOINT:
        *ux_signal = SIGTRAP;
        break;
    }
}
 
@end
