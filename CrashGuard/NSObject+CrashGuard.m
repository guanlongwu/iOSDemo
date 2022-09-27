//
//  NSObject+CrashGuard.m
//  YYTool
//
//  Created by wugl on 2022/6/2.
//

#import "NSObject+CrashGuard.h"
#import "KMSwizzle.h"
#import <objc/message.h>

@implementation NSObject (CrashGuard)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        KMSwizzleMethod([self class],
                        @selector(methodSignatureForSelector:),
                        [self class],
                        @selector(gl_methodSignatureForSelector:));
        KMSwizzleMethod([self class],
                        @selector(forwardInvocation:),
                        [self class],
                        @selector(gl_forwardInvocation:));
        KMSwizzleMethod([self class],
                        @selector(instanceMethodSignatureForSelector:),
                        [self class],
                        @selector(gl_instanceMethodSignatureForSelector:));
        
        KMSwizzleMethod(object_getClass([self class]), @selector(eat), object_getClass([self class]), @selector(gl_eat));
    });
}

- (NSMethodSignature *)gl_methodSignatureForSelector:(SEL)aSelector {
    //方法签名
    NSMethodSignature* method = [self gl_methodSignatureForSelector:aSelector];
    if (!method) {
        // 类没有这个方法签名，需要动态添加一个方法签名
        method = [NSMethodSignature signatureWithObjCTypes:"@@:"];
    }
    return method;
}

+ (NSMethodSignature *)gl_instanceMethodSignatureForSelector:(SEL)aSelector
{
    //方法签名
    NSMethodSignature* method = [self gl_instanceMethodSignatureForSelector:aSelector];
    if (!method) {
        // 类没有这个方法签名，需要动态添加一个方法签名
        method = [NSMethodSignature signatureWithObjCTypes:"@@:"];
    }
    return method;
}

- (void)gl_forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"NSObject+CrashLogHandle---在类:%@中 未实现该方法:%@",NSStringFromClass([anInvocation.target class]),NSStringFromSelector(anInvocation.selector));
    NSString* selector = NSStringFromSelector(anInvocation.selector);
    [anInvocation setSelector:@selector(crashGuard)];
    [anInvocation invoke];
}

- (id)crashGuard
{
    NSLog(@"unregnized method. crash safe");
    return nil;
}


#pragma mark - hook 类方法

+ (void)eat
{
    NSLog(@"%s", __func__);
}

+ (void)gl_eat
{
    NSLog(@"%s", __func__);
    [self gl_eat];
}

@end
