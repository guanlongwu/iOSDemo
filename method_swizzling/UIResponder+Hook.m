//
//  UIResponder+Hook.m
//  YYInterview
//
//  Created by wugl on 2022/5/17.
//

#import "UIResponder+Hook.h"
#import "KMSwizzle.h"

@implementation UIResponder (Hook)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        KMSwizzleMethod([self class],
                        @selector(sendAction:to:forEvent:),
                        [self class],
                        @selector(gl_sendAction:to:forEvent:));
        KMSwizzleMethod([self class],
                        @selector(hitTest:withEvent:),
                        [self class],
                        @selector(gl_hitTest:withEvent:));
    });
}

- (void)gl_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event
{
//    NSLog(@"%s", __func__);
    [self gl_sendAction:action to:target forEvent:event];
}

- (UIView *)gl_hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
//    NSLog(@"%s", __func__);
    return [self gl_hitTest:point withEvent:event];
}

@end
