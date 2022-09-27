//
//  UIWindow+Hook.m
//  YYInterview
//
//  Created by wugl on 2022/5/17.
//

#import "UIWindow+Hook.h"
#import "KMSwizzle.h"

@implementation UIWindow (Hook)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        KMSwizzleMethod([self class],
                        @selector(sendEvent:),
                        [self class],
                        @selector(gl_sendEvent:));
        KMSwizzleMethod([self class],
                        @selector(hitTest:withEvent:),
                        [self class],
                        @selector(gl_hitTest:withEvent:));
    });
}

- (void)gl_sendEvent:(UIEvent *)event
{
//    NSLog(@"%s", __func__);
    [self gl_sendEvent:event];
}

- (UIView *)gl_hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
//    NSLog(@"%s", __func__);
    return [self gl_hitTest:point withEvent:event];
}

@end
