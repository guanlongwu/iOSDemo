//
//  GLUncaughtExceptionHandler.m
//  YYTool
//
//  Created by wugl on 2022/8/19.
//

#import "GLUncaughtExceptionHandler.h"

// 记录之前的崩溃回调函数
static NSUncaughtExceptionHandler *previousUncaughtExceptionHandler = NULL;
 
@implementation GLUncaughtExceptionHandler
 
#pragma mark - Register
 
+ (void)registerHandler {
    //将先前别人注册的handler取出并备份
    previousUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
    
    NSSetUncaughtExceptionHandler(&UncaughtExceptionHandler);
}
 
#pragma mark - Private
 
// 崩溃时的回调函数
static void UncaughtExceptionHandler(NSException * exception) {
    // 异常的堆栈信息
    NSArray * stackArray = [exception callStackSymbols];
    // 出现异常的原因
    NSString * reason = [exception reason];
    // 异常名称
    NSString * name = [exception name];
    
    
    // 保存崩溃日志到沙盒cache目录
//    [NWCrashTool saveCrashLog:exceptionInfo fileName:@"Crash(Uncaught)"];
    
    NSLog(@"\n\n\n======== ❤️❤️❤️ uncaught Exception of type: NSException 异常错误报告 ========\n\n");
    
    NSLog(@"\n❤️ name:%@\n\n", name);
    
    NSLog(@"\n❤️ reason:\n\n%@\n\n", reason);
    
    NSLog(@"\n❤️ [NSException] callStackSymbols:\n\n%@", [stackArray componentsJoinedByString:@"\n"]);
    
    NSLog(@"\n\n====\n\n\n\n");
    
    //在自己handler处理完后自觉把别人的handler注册回去，规规矩矩的传递
    if (previousUncaughtExceptionHandler) {
        previousUncaughtExceptionHandler(exception);
    }
    
    // 杀掉程序，这样可以防止同时抛出的SIGABRT被SignalException捕获
//    kill(getpid(), SIGKILL);
}
 
@end
