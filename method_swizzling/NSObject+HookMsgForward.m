//
//  NSObject+HookMsgForward.m
//  YYTool
//
//  Created by wugl on 2022/6/7.
//

#import "NSObject+HookMsgForward.h"
#import "KMSwizzle.h"

@implementation NSObject (HookMsgForward)

+ (void)load {
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
    });
}

- (NSMethodSignature *)gl_methodSignatureForSelector:(SEL)aSelector
{
    NSLog(@"%@", NSStringFromSelector(aSelector));
    NSMethodSignature *sig = [self gl_methodSignatureForSelector:aSelector];
    return sig;
}

- (void)gl_forwardInvocation:(NSInvocation *)anInvocation
{
    NSLog(@"selector : %@, target : %@", NSStringFromSelector(anInvocation.selector), anInvocation.target);
    [self gl_forwardInvocation:anInvocation];
}


@end
