//
//  AspectsAction.m
//  YYTool
//
//  Created by wugl on 2022/7/14.
//

#import "AspectsAction.h"
#import "Aspects.h"
#import <objc/runtime.h>

@implementation AspectsAction

- (void)doWork
{
    // object aop
//    [AspectsAction _hookObject];
    
    // class aop
//    [AspectsAction _hookClass];
    

    NSError *error = nil;
    
    // [self class]；因为self是对象，获取的是类对象；[AspectsAction class] 获取的是 class本身
    // 所以要hook类方法，需要调用 object_getClass(self.class)
//    [[self class]] aspect_hookSelector:@selector(_eat) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> aspectInfo) {
//        NSLog(@"before eat");
//    } error:&error];
    
    [object_getClass([self class]) aspect_hookSelector:@selector(_eat) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> aspectInfo) {
        NSLog(@"before eat");
    } error:&error];
    
    [AspectsAction _eat];
}

+ (void)_hookClass
{
    id obj1 = object_getClass(self);
    id obj2 = [self class];
    
    BOOL isMetaClass = class_isMetaClass(obj1);
    
    isMetaClass = class_isMetaClass(obj2);
    
    NSError *error = nil;
//    [object_getClass(self) aspect_hookSelector:@selector(_eat) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> aspectInfo) {
//        NSLog(@"before eat");
//    } error:&error];
    
    [[self class] aspect_hookSelector:@selector(_eat) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> aspectInfo) {
        NSLog(@"before eat");
    } error:&error];
    
    [AspectsAction _eat];
}

- (void)_run
{
    NSLog(@"run");
}




+ (void)_hookObject
{
    id obj = [AspectsAction new];
    NSError *error = nil;
//    [obj aspect_hookSelector:@selector(_run) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> aspectInfo){
//        NSLog(@"before run");
//    } error:&error];
    
//    [AspectsAction aspect_hookSelector:@selector(_run) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> aspectInfo){
//        NSLog(@"before run");
//    } error:&error];
    
    [self aspect_hookSelector:@selector(_run) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> aspectInfo){
        NSLog(@"before run");
    } error:&error];
    
    [obj _run];
}


+ (void)_eat
{
    NSLog(@"eat");
}


@end
