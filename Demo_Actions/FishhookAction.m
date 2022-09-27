//
//  FishhookAction.m
//  YYTool
//
//  Created by wugl on 2022/7/14.
//

#import "FishhookAction.h"
#import "fishhook.h"

@implementation FishhookAction

- (void)doWork
{
    NSLog(@"我是大帅哥");
    [self _testFishhook];
    NSLog(@"%@, 你是大美女", @"韩梅梅");
}



#pragma mark - fishhook

// 定义一个函数指针用来接收并保存系统C函数的实现地址
static int(*ori_nslog)(NSString * format, ...);

void gl_nslog(NSString * format, ...)
{
//    NSString *str = [NSString stringWithFormat:@"我hook住你啦：%@", format];
    format = [format stringByAppendingFormat:@" ~~ 我hook住你啦 ~~ "];
//    NSLog(@"我hook住你啦：%@", log);
    
    va_list args;

    va_start(args, format);
    
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    
    va_end(args);
    
    ori_nslog(message);
}

- (void)_testFishhook
{
    struct rebinding rebind;
    rebind.name = "NSLog";
    rebind.replacement = gl_nslog; // 将自定义的函数赋值给replacement
    rebind.replaced = (void *)&ori_nslog; // 使用自定义的函数指针来接收printf函数原有的实现
    
    struct rebinding rebs[1] = {rebind};
    rebind_symbols(rebs, 1);

}



@end
