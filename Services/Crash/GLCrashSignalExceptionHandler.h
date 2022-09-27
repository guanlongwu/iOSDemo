//
//  GLCrashSignalExceptionHandler.h
//  YYTool
//
//  Created by wugl on 2022/8/19.
//
/**
 Unix信号:signal(SIGSEGV,signalHandler);
 SIGABRT是应用程序在未捕获NSException或obj_exception_抛出时向自身发送的BSD信号。
 但是，这并不能代表SIGABRT就是 NSException导致，因为SIGABRT是调用abort()生成的信号。
 若程序因NSException而Crash，系统日志中的Last Exception Backtrace信息是完整准确的。
 
 tips:
 这里还发现在 m1 mac 下需要关闭下面的 Debug executable 现象后才能捕获到 Mach 异常，在 intel mac 下开启与关闭 Debug executable 选项都能捕获到 Mach 异常。
 
 */


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GLCrashSignalExceptionHandler : NSObject

+ (void)registerHandler;

@end

NS_ASSUME_NONNULL_END
