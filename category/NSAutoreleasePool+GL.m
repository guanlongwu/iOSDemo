//
//  NSAutoreleasePool+GL.m
//  YYInterview
//
//  Created by wugl on 2022/5/23.
//

#import "NSAutoreleasePool+GL.h"
#import "KMSwizzle.h"

@implementation NSAutoreleasePool (GL)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        KMSwizzleMethod([self class],
                        @selector(addObject:),
                        [self class],
                        @selector(gl_addObject:));
        KMSwizzleMethod([self class],
                        @selector(drain),
                        [self class],
                        @selector(gl_drain));
    });
}

- (void)gl_addObject:(id)anObject
{
//    NSLog(@"%s", __func__);
    [self gl_addObject:anObject];
}

- (void)gl_drain
{
//    NSLog(@"%s", __func__);
    [self gl_drain];
}


@end
