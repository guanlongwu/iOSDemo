//
//  GLObject.m
//  YYInterview
//
//  Created by wugl on 2022/4/27.
//

#import "GLObject.h"
#import <objc/runtime.h>
#import <objc/message.h>

//static GLObject *staticObj = nil;

@implementation GLObject

- (id)copyWithZone:(NSZone *)zone
{
    GLObject *model = [[GLObject alloc] init];
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    for (int i = 0; i<count; i++) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        NSString *propertyName = [NSString stringWithUTF8String:name];
        id value = [self valueForKey:propertyName];
        if (value) {
            [model setValue:value forKey:propertyName];
        }
    }
    free(properties);
    return model;
}

- (instancetype)shareInstance
{
    static GLObject *instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[GLObject alloc] init];
    });
    return instance;
}

- (void)dealloc {
//    if (_name.intValue == 999998 || _name.intValue == 1) {
//        NSLog(@"%s -- name:%@ -- %@", __func__, _name, self);
//    }
//    NSLog(@"--%s , name :%@", __func__, _name);
}

- (void)setName:(NSString *)name {
    if (_name != name) {
        _name = name;
    }
    if (self.block) {
        self.block(name);
    }
}

- (void)doWork
{
    NSLog(@"%s", __func__);
}

- (id)run
{
    NSLog(@"GLObject run");
    return [self shareInstance];
}

@end
