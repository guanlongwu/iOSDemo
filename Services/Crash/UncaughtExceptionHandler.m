//
//  UncaughtExceptionHandler.m
//  YYTool
//
//  Created by wugl on 2022/8/26.
//

#import "UncaughtExceptionHandler.h"

#import <UIKit/UIDevice.h>
#import <libkern/OSAtomic.h>
#import <execinfo.h>
#import <stdatomic.h>

NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
NSString * const UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";
NSString * const UncaughtExceptionHandlerFileKey = @"UncaughtExceptionHandlerFileKey";

atomic_int UncaughtExceptionCount = 0;
const int32_t UncaughtExceptionMaximum = 10;

// 这里异常发生时跳过函数调用堆栈中的 4 个 frame，如下 4 个：
/*
 "0   dSYMDemo                            0x00000001042541eb +[UncaughtExceptionHandler backtrace] + 59",
 "1   dSYMDemo                            0x0000000104253edc mySignalHandler + 76",
 "2   libsystem_platform.dylib            0x000000010e774e2d _sigtramp + 29",
 "3   ???                                 0x0000600002932720 0x0 + 105553159464736",
*/
const NSInteger UncaughtExceptionHandlerSkipAddressCount = 4;
//const NSInteger UncaughtExceptionHandlerReportAddressCount = 5;

void mySignalHandler(int signal);

@implementation UncaughtExceptionHandler

+ (void)installUncaughtExceptionHandler
{
    // 将之前注册的 未捕获异常处理函数 取出并备份，防止覆盖
    previousUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
    // Objective-C 异常捕获（越界、参数无效等）
    NSSetUncaughtExceptionHandler(&UncaughtExceptionHandlers);
    
    // 信号量截断，当抛出信号时会回调 MySignalHandler 函数
    signal(SIGABRT, mySignalHandler);
    signal(SIGILL, mySignalHandler);
    signal(SIGSEGV, mySignalHandler);
    signal(SIGFPE, mySignalHandler);
    signal(SIGBUS, mySignalHandler);
    signal(SIGPIPE, mySignalHandler);
}

+ (void)setSignalHandlerInAdvance
{
    struct sigaction act;
    // 当 sa_flags 设为 SA_SIGINFO 时，设定 sa_sigaction 来指定信号处理函数
    act.sa_flags = SA_SIGINFO;
    act.sa_sigaction = test_signal_action_handler;
    sigaction(SIGABRT, &act, NULL);
}

static void test_signal_action_handler(int signo, siginfo_t *si, void *ucontext)
{
    NSLog(@"🏵🏵🏵 [sigaction handler] - handle signal: %d", signo);
    
    // handle siginfo_t
    NSLog(@"🏵🏵🏵 siginfo: {\n si_signo: %d,\n si_errno: %d,\n si_code: %d,\n si_pid: %d,\n si_uid: %d,\n si_status: %d,\n si_value: %d\n }",
          si->si_signo,
          si->si_errno,
          si->si_code,
          si->si_pid,
          si->si_uid,
          si->si_status,
          si->si_value.sival_int);
}

// 获取函数堆栈信息
+ (NSArray *)backtrace
{
    void* callstack[128];
    
    // 用于获取当前线程的函数调用堆栈，返回实际获取的指针个数
    int frames = backtrace(callstack, 128);
    // 从 backtrace 函数获取的信息转化为一个字符串数组
    char **strs = backtrace_symbols(callstack, frames);
    
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    
    // 越过最前面的 4 个 frame
    if (frames > UncaughtExceptionHandlerSkipAddressCount) {
        for (int i = UncaughtExceptionHandlerSkipAddressCount; i < frames; ++i) {
            [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
        }
    }
    
    NSLog(@"🏵🏵🏵 backtrace_symbols 异常发生时的堆栈：%@", backtrace);
    
    free(strs);
    
    return backtrace;
}

- (void)saveCreash:(NSException *)exception file:(NSString *)file
{
    // 异常发生时的堆栈信息
    NSArray *stackArray = [exception callStackSymbols];
    if (!stackArray || stackArray.count <= 0) {
        stackArray = [exception.userInfo objectForKey:UncaughtExceptionHandlerAddressesKey];
    }
    
    // 出现异常的原因
    NSString *reason = [exception reason];
    // 异常名称
    NSString *name = [exception name];
    
    NSString *_libPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:file];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_libPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:_libPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval a = [date timeIntervalSince1970];
    NSString *timeString = [NSString stringWithFormat:@"%f", a];
    
    NSString *savePath = [_libPath stringByAppendingFormat:@"/error%@.log", timeString];
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception reason：%@\nException name：%@\nException stack：%@", name, reason, stackArray];
    BOOL sucess = [exceptionInfo writeToFile:savePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSLog(@"🏵🏵🏵 保存崩溃日志 sucess:%d, %@", sucess, savePath);
}

// 异常处理方法
- (void)handleException:(NSException *)exception
{
    NSDictionary *userInfo = [exception userInfo];
    [self saveCreash:exception file:[userInfo objectForKey:UncaughtExceptionHandlerFileKey]];
    
    NSSetUncaughtExceptionHandler(NULL);
//    signal(SIGABRT, SIG_DFL);
//    signal(SIGILL, SIG_DFL);
//    signal(SIGSEGV, SIG_DFL);
//    signal(SIGFPE, SIG_DFL);
//    signal(SIGBUS, SIG_DFL);
//    signal(SIGPIPE, SIG_DFL);
    
    if ([[exception name] isEqual:UncaughtExceptionHandlerSignalExceptionName]) {
        int signalNumber = [[[exception userInfo] objectForKey:UncaughtExceptionHandlerSignalKey] intValue];
        
        NSLog(@"🏵🏵🏵 抓到 signal 异常：%d", signalNumber);
        
        // 如果是 signal 异常
        kill(getpid(), [[[exception userInfo] objectForKey:UncaughtExceptionHandlerSignalKey] intValue]);
    } else {
        NSLog(@"🏵🏵🏵 抓到 Objective-C 异常：%@", exception);
        
        // 如果是 Objective-C 异常
        [exception raise];
        
        // 在自己的异常处理操作完毕后，调用先前别人注册的未捕获异常处理函数，并把原始的 exception 进行传递
        if (previousUncaughtExceptionHandler) {
            previousUncaughtExceptionHandler(exception);
        }
        else {
            // 如果是 Objective-C 异常
            kill(getpid(), SIGKILL);
        }
    }
}

// 获取应用信息
NSString* getAppInfo(void)
{
    NSString *appInfo = [NSString stringWithFormat:@"App : %@ %@(%@) Device : %@ OS Version : %@ %@",
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
                         [UIDevice currentDevice].model,
                         [UIDevice currentDevice].systemName,
                         [UIDevice currentDevice].systemVersion];
    return appInfo;
}

static NSUncaughtExceptionHandler *previousUncaughtExceptionHandler = NULL;

// NSSetUncaughtExceptionHandler 捕获异常的调用方法，利用 NSSetUncaughtExceptionHandler，当程序异常退出的时候，可以先进行处理，然后做一些自定义的动作
void UncaughtExceptionHandlers (NSException *exception) {
    // 原子自增 1
    int32_t exceptionCount = atomic_fetch_add(&UncaughtExceptionCount, 1);
    if (exceptionCount > UncaughtExceptionMaximum) { return; }
    
    // 异常发生时的函数堆栈
    NSArray *callStack = [UncaughtExceptionHandler backtrace];
    
    NSLog(@"\n\n🍀🍀🍀 NSException.callStackSymbols 异常发生时的堆栈：%@", [[exception callStackSymbols] componentsJoinedByString:@"\n"]);
    
    // 组装 userInfo 数据
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
    [userInfo setObject:callStack forKey:UncaughtExceptionHandlerAddressesKey];
    [userInfo setObject:@"Objective-C Crash" forKey:UncaughtExceptionHandlerFileKey];
    
    NSException *medianException = [NSException exceptionWithName:[exception name]
                                                           reason:[exception reason]
                                                         userInfo:userInfo];
    
    // Objective-C 异常和 signal 都放在 handleException: 函数中进行处理
    [[[UncaughtExceptionHandler alloc] init] performSelectorOnMainThread:@selector(handleException:) withObject:medianException waitUntilDone:YES];
}

// Signal 处理方法
void mySignalHandler(int signal)
{
    // 原子自增 1
    int32_t exceptionCount = atomic_fetch_add(&UncaughtExceptionCount, 1);
    if (exceptionCount > UncaughtExceptionMaximum) { return; }
    
    // 异常发生时的函数堆栈
    NSArray *callStack = [UncaughtExceptionHandler backtrace];
    
    // 组装 userInfo 数据
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:signal] forKey:UncaughtExceptionHandlerSignalKey];
    [userInfo setObject:callStack forKey:UncaughtExceptionHandlerAddressesKey];
    [userInfo setObject:@"Signal Crash" forKey:UncaughtExceptionHandlerFileKey];
    
    // 构建一个 NSException 对象
    NSException *medianException = [NSException exceptionWithName:UncaughtExceptionHandlerSignalExceptionName
                                                     reason:[NSString stringWithFormat:NSLocalizedString(@"Signal %d was raised.\n" @"%@", nil), signal, getAppInfo()]
                                                   userInfo:userInfo];
    
    // Objective-C 异常和 signal 都放在 handleException: 函数中进行处理
    [[[UncaughtExceptionHandler alloc] init] performSelectorOnMainThread:@selector(handleException:) withObject:medianException  waitUntilDone:YES];
}

@end
