//
//  KSCrashAction.m
//  YYTool
//
//  Created by wugl on 2022/8/11.
//

#import "KSCrashAction.h"
#import "GLCrashSignalExceptionHandler.h"
#import "GLUncaughtExceptionHandler.h"
#import "GLCrashMachExceptionHandler.h"
#import "UncaughtExceptionHandler.h"
#import "BSBacktraceLogger.h"

#import "KSCrash.h"
#import "KSCrashInstallationStandard.h"
#import "KSCrashInstallationEmail.h"

#include "KSDynamicLinker.h"
#include <mach/mach.h>
#include <pthread.h>
#include <signal.h>
#include "KSSymbolicator.h"
#import "KSID.h"
#include "KSCrashMonitor.h"
#include "KSStackCursor_Backtrace.h"

#include "KSMachineContext.h"

#include <sys/types.h>
#include "KSCrashMonitorType.h"
#include "KSMachineContext.h"
#import "KSCrashMonitorContext.h"

#include <stdbool.h>
#include <stdint.h>

#import "GLObject.h"

static KSCrash_MonitorContext g_monitorContext;
static NSUncaughtExceptionHandler* g_previousUncaughtExceptionHandler;

@interface KSCrashAction ()
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation KSCrashAction

- (void)doWork
{
//    [self backtraceAction];
//    return;
    
//    [self setupKSCrash];
    
    [GLUncaughtExceptionHandler registerHandler];
    [GLCrashSignalExceptionHandler registerHandler];
    [GLCrashMachExceptionHandler registerHandler];
    
//    [UncaughtExceptionHandler installUncaughtExceptionHandler];
    
//    [self setEnabled:YES];
//    NSString *bs = [BSBacktraceLogger bs_backtraceOfCurrentThread];
//    NSLog(@"wugl:%@\n\n\n", bs);
//
//    NSLog(@"callbacksymbol:%@\n\n\n", [NSThread callStackSymbols]);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        

//        [self backgroudCrash];
        [self wildPointerCall];
//        [self wakeupException];
//        [self testSignalCrash];
//        [self testMachCrash];
//        [self deadLock];
//        [self sigsegv_sigbus];
//        [self deadLoopCrash];
//        [self rangeCrash];  // nsexception捕获之后，也会被mach异常捕获，mach异常堆栈不对，接着，会转换成unix异常信号，但是signal exception堆栈不对。
//        [self gcdCrash];    // mach exception捕获之后，并没有转成signal信号，singnal捕获不了（需要在scheme editor把debug excutable 关闭，signal才能捕获）
//        [self sigabrtCrash];
//        [self illegalMemoryAccess]; // NSException捕获不了, mach exception可以捕获，需要指定 EXC_MASK_BREAKPOINT 类型，并没有转成signal信号，signal捕获不了（需要在scheme editor把debug excutable 关闭，signal才能捕获）
//        [self illegalArithmetic];
        
        @try {
            
//            [self rangeCrash];
//            [self gcdCrash];
//            [self illegalMemoryAccess]; // try catch 只能捕获NSException OC异常，不能捕获mach/signal异常
//            [self illegalArithmetic];
            
        } @catch (NSException *exception) {
            
            // 验证发现：传了false 在挂起线程后，并不会把线程恢复
            handleException(exception, true);
//            handleException(exception, false);
        }
        
    });
    
}

- (void)wakeupException
{
    for (int i=0; i<9999999; i++) {
//        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSString *label = [NSString stringWithFormat:@"%@", @(i)];
        const char *lab = [label cStringUsingEncoding:NSUTF8StringEncoding];
        dispatch_queue_t serialQueue = dispatch_queue_create(lab, DISPATCH_QUEUE_SERIAL);
        dispatch_async(serialQueue, ^{
            int m = 0;
            for (int j=0; j<5999999; j++) {
                m += j;
            }
            NSLog(@"\n\n%@\n\n", [NSThread currentThread]);
//            dispatch_semaphore_signal(semaphore);
        });
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
}

/// 数组越界这种是属于可被捕获的崩溃信号 --- NSException OC异常
/// Objective-C 异常是应用层面的异常，我们可以通过 @try @catch（捕获）或 NSSetUncaughtExceptionHandler（记录）函数来捕获或记录异常（处理异常）
/// 而 Objective-C 异常之外的例如对内存访问错误、重复释放等错误引起的 Mach 异常需要通过其他方式进行处理
/// （如野指针访问、MRC 下重复 release 等会造成 EXC_BAD_ACCESS 类型的 Mach 异常导致进程中止。
/// 直接调用 abort 函数其内部调用 pthread_kill 对当前线程发出 SIGABRT 信号后进程被中止，
/// 或者我们也可以自己手动调用 pthread_kill(pthread_self(), SIGSEGV) 中止进程此时我们便可以收到 Signal 回调）
/// Objective-C 异常（NSException）是应用层面的异常，
/// 它与其他两者的最大区别就是 Mach 异常与 Unix 信号是硬件层面的异常，
/// NSException 是软件层面的异常，且它们三者中两者之间有一些迁移转化关系。
- (void)rangeCrash
{
    NSArray *testArray = @[@"s1",@"s2"];
    NSLog(@"%@",testArray[10]);
    
    
    //2.ios崩溃
    // 被oc exception捕获到，然后转换成signal信号，被signal捕获（nsexception成功获取堆栈，signal堆栈不准确）
//    NSArray *array= @[@"tom",@"xxx",@"ooo"];
//    NSLog(@"%@-%p", array, array);
//    [array objectAtIndex:5];
}

- (void)sigabrtCrash
{
    // 1.信号量
    int list[2]={1,2};
    int *p = list;
    free(p);//导致SIGABRT的错误，因为内存中根本就没有这个空间，哪来的free，就在栈中的对象而已
    p[1] = 5;
    // 被mach exception捕获到，然后转换成signal信号，被signal捕获（signal成功获取堆栈）
    
}

- (void)deadLoopCrash
{
    // M1记得把debugger选项去掉勾选（去掉勾选是  sigbus，不去掉就是 sigsegv）
    [self deadLoopCrash];   // EXC_BAD_ACCESS(SIGSEGV)
}

- (void)sigsegv_sigbus
{
    // exception:1 (EXC_BAD_ACCESS)、code:1（SIGSEGV）、subcode:1(KERN_INVALID_ADDRESS)
//    int *pi = (int*)0x00001111; //0x1024f4111;
//    *pi = 17;
    
    // exception:1 (EXC_BAD_ACCESS)、code:1（SIGSEGV）、subcode:1(KERN_INVALID_ADDRESS)
//    char *pc = (char*)0x00001111; // 0x1024f4148
//    *pc = 17;
    
    // exception:1 (EXC_BAD_ACCESS)、code:2（SIGBUS）、subcode:1(KERN_INVALID_ADDRESS)
    char *s = "hello world";
    *s = 'H';
}

- (void)testMachCrash
{
    // exception:1 (EXC_BAD_ACCESS)、code:1（SIGSEGV）、subcode:1(KERN_INVALID_ADDRESS)
    *((int*)(0x1234)) = 122 ;
}

- (void)testSignalCrash
{
    kill(0, SIGTRAP);
}


- (void)deadLock
{
    NSLock *_lock = [[NSLock alloc]init];
    [_lock lock];
    [_lock lock];//多次上锁
}

/// 野指针访问EXC_BAD_ACCESS
- (void)illegalMemoryAccess
{
    __unsafe_unretained NSObject *objc = [[NSObject alloc] init];
    NSLog(@"✳️✳️✳️ objc: %@", objc);
}

/// 除零操作EXC_ARITHMETIC
- (void)illegalArithmetic
{
    float a = 0.0f;
    float b = 15.0f;
    float result = b / a;
    NSLog(@"🏵🏵🏵 %f", result);
}

/// gcd group过度出组，貌似不能被捕获（原因：待考究）
- (void)gcdCrash
{
    dispatch_group_t group = dispatch_group_create();
    
    void(^asyncBlock)(void) = ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            dispatch_group_leave(group);
            dispatch_group_leave(group);
        });
    };
    dispatch_group_enter(group);
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (asyncBlock) {
            asyncBlock();
        }
    });
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"dispatch_group_notify");
    });
    
    // 设置超时时间
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSInteger res = dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)));
        if (0 != res) {
            // 超时了还未处理完group事件
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"dispatch_group_wait timeout");
            });
        }
    });
}


#pragma mark - 野指针

- (void)wildPointerCall
{
    __unsafe_unretained GLObject *obj = nil;
    {
        GLObject *tmpObj = [GLObject new];
        obj = tmpObj;
    }
    [obj doWork];
}




#pragma mark - 信号不可捕获的崩溃

/// 后台崩溃
- (void)backgroudCrash
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backgroudAction) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [self backgroudAction];
}

- (void)backgroudAction
{
    NSLog(@"wugl");
    for (int i=0; i<9999999; i++) {
//        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSString *label = [NSString stringWithFormat:@"%@", @(i)];
        const char *lab = [label cStringUsingEncoding:NSUTF8StringEncoding];
        dispatch_queue_t serialQueue = dispatch_queue_create(lab, DISPATCH_QUEUE_SERIAL);
        dispatch_async(serialQueue, ^{
            int m = 0;
            for (int j=0; j<5999999; j++) {
                m += j;
            }
            NSLog(@"\n\n%@\n\n", [NSThread currentThread]);
//            dispatch_semaphore_signal(semaphore);
        });
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
}



/// 内存打爆
- (void)jetsamCrash
{
    
}



#pragma mark -

static void handleException(NSException* exception, BOOL currentSnapshotUserReported) {

    thread_act_array_t threads = NULL;
    mach_msg_type_number_t numThreads = 0;
    /// 获取挂起的线程，以及挂起的线程数量
    ksmc_suspendEnvironment(&threads, &numThreads);
    kscm_notifyFatalExceptionCaptured(false);

    NSLog(@"Filling out context.");
    
    NSArray *callstackSymbols = [exception callStackSymbols];
    NSLog(@"callback symbols: %@\n\n", callstackSymbols);
    
    NSArray* addresses = [exception callStackReturnAddresses];
    NSLog(@"callback addresses: %@\n\n", addresses);
    
    NSUInteger numFrames = addresses.count;
    uintptr_t* callstack = malloc(numFrames * sizeof(*callstack));
    for(NSUInteger i = 0; i < numFrames; i++)
    {
        callstack[i] = (uintptr_t)[addresses[i] unsignedLongLongValue];
    }

    char eventID[37];
    ksid_generate(eventID);
    KSMC_NEW_CONTEXT(machineContext);
    ksmc_getContextForThread(ksthread_self(), machineContext, true);
    KSStackCursor cursor;
    kssc_initWithBacktrace(&cursor, callstack, (int)numFrames, 0);

    KSCrash_MonitorContext* crashContext = &g_monitorContext;
    memset(crashContext, 0, sizeof(*crashContext));
    crashContext->crashType = KSCrashMonitorTypeNSException;
    crashContext->eventID = eventID;
    crashContext->offendingMachineContext = machineContext;
    crashContext->registersAreValid = false;
    crashContext->NSException.name = [[exception name] UTF8String];
    crashContext->NSException.userInfo = [[NSString stringWithFormat:@"%@", exception.userInfo] UTF8String];
    crashContext->exceptionName = crashContext->NSException.name;
    crashContext->crashReason = [[exception reason] UTF8String];
    crashContext->stackCursor = &cursor;
    crashContext->currentSnapshotUserReported = currentSnapshotUserReported;

    NSLog(@"Calling main crash handler.");
    kscm_handleException(crashContext);

    free(callstack);
    if (currentSnapshotUserReported) {
        ksmc_resumeEnvironment(threads, numThreads);
    }
    if (g_previousUncaughtExceptionHandler != NULL)
    {
        NSLog(@"Calling original exception handler.");
        g_previousUncaughtExceptionHandler(exception);
    }
}

static void handleUncaughtException(NSException* exception) {
    handleException(exception, false);
}

- (void)setEnabled:(bool)isEnabled
{
    if(isEnabled)
    {
        NSLog(@"Backing up original handler.");
        g_previousUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
        
        NSLog(@"Setting new handler.");
        NSSetUncaughtExceptionHandler(&handleUncaughtException);
//        KSCrash.sharedInstance.uncaughtExceptionHandler = &handleUncaughtException;
//        KSCrash.sharedInstance.currentSnapshotUserReportedExceptionHandler = &handleCurrentSnapshotUserReportedException;
    }
    else
    {
        NSLog(@"Restoring original handler.");
        NSSetUncaughtExceptionHandler(g_previousUncaughtExceptionHandler);
    }

}


#pragma mark - BSBacktraceLogger

- (void)backtraceAction
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        BSLOG  // 打印当前线程的调用栈
        BSLOG_ALL  // 打印所有线程的调用栈
        BSLOG_MAIN  // 打印主线程调用栈
    });
    [self foo];
}

- (void)foo {
    [self bar];
}

- (void)bar {
    while (true) {
        ;
    }
}


#pragma mark - KSCrash

- (void)setupKSCrash
{
    KSCrashInstallation* installation = [self makeEmailInstallation];
//    installStandered.url = [NSURL URLWithString:@"https://collector.bughd.com/kscrash?key=您的general key"];
    /// 注册 crash handler
    [installation install];
//
//    [installation sendAllReportsWithCompletion:^(NSArray *filteredReports,BOOL completed, NSError *error) {
//        NSLog(@"%@",filteredReports);
//    }];
    
}

- (KSCrashInstallation *)makeEmailInstallation
{
    NSString* emailAddress = @"1258702475@qq.com";
    
    KSCrashInstallationEmail* email = [KSCrashInstallationEmail sharedInstance];
    email.recipients = @[emailAddress];
    email.subject = @"Crash Report";
    email.message = @"This is a crash report";
    email.filenameFmt = @"crash-report-%d.txt.gz";
    
//    [email addConditionalAlertWithTitle:@"Crash Detected"
//                                message:@"The app crashed last time it was launched. Send a crash report?"
//                              yesAnswer:@"Sure!"
//                               noAnswer:@"No thanks"];
    
    // Uncomment to send Apple style reports instead of JSON.
    [email setReportStyle:KSCrashEmailReportStyleApple useDefaultFilenameFormat:YES];

    return email;
}

@end
