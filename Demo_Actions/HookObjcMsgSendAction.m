//
//  HookObjcMsgSendAction.m
//  YYTool
//
//  Created by wugl on 2022/9/15.
//

#import "HookObjcMsgSendAction.h"
#import "TimeProfiler.h"
#import "GLCrashSignalExceptionHandler.h"
#import "GLUncaughtExceptionHandler.h"
#import "GLCrashMachExceptionHandler.h"

@implementation HookObjcMsgSendAction

- (void)doWork
{
    
//    [GLUncaughtExceptionHandler registerHandler];
//    [GLCrashSignalExceptionHandler registerHandler];
//    [GLCrashMachExceptionHandler registerHandler];
    
    NSLog(@"\n\n\n ==== 开始统计 ==== \n\n\n");

    [[TimeProfiler shareInstance] TPStartTrace:"hook objc_msgSend"];
    
    static int value = 0;
    for (int i=0; i<9999999; i++) {
        value += i;
    }
    
    [[TimeProfiler shareInstance] TPStopTrace];
    
    NSLog(@"\n\n\n ==== 结束统计 ==== \n\n\n");
}

@end
