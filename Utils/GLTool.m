//
//  GLTool.m
//  YYTool
//
//  Created by wugl on 2022/6/7.
//

#import "GLTool.h"
#import <objc/runtime.h>

@implementation GLTool

+ (NSArray <NSString *>*)propertiesForClass:(Class)cls
{
    NSMutableArray *arr = [NSMutableArray array];
    unsigned int count;
    //获取属性列表
    objc_property_t *propertyList = class_copyPropertyList(cls, &count);
    for (unsigned int i=0; i<count; i++) {
        const char *propertyName = property_getName(propertyList[i]);
        NSString *property = [NSString stringWithUTF8String:propertyName];
        NSLog(@"property---->%@", property);
        [arr addObject:property];
    }
    return arr;
}

+ (NSArray <NSString *>*)methodsForClass:(Class)cls
{
    NSMutableArray *arr = [NSMutableArray array];
    unsigned int count;
    //获取方法列表
    Method *methodList = class_copyMethodList(cls, &count);
    for (unsigned int i=0; i<count; i++) {
        Method method = methodList[i];
        NSString *methodStr = NSStringFromSelector(method_getName(method));
        NSLog(@"method---->%@", methodStr);
        [arr addObject:methodStr];
    }
    return arr;
}

+ (NSArray <NSString *>*)ivarsForClass:(Class)cls
{
    NSMutableArray *arr = [NSMutableArray array];
    unsigned int count;
    //获取成员变量列表
    Ivar *ivarList = class_copyIvarList(cls, &count);
    for (unsigned int i=0; i<count; i++) {
        Ivar ivar = ivarList[i];
        const char *ivarName = ivar_getName(ivar);
        NSString *ivarStr = [NSString stringWithUTF8String:ivarName];
        NSLog(@"ivar---->%@", ivarStr);
        [arr addObject:ivarStr];
    }
    return arr;
}

+ (NSArray <NSString *>*)protocolsForClass:(Class)cls
{
    NSMutableArray *arr = [NSMutableArray array];
    unsigned int count;
    //获取协议列表
    __unsafe_unretained Protocol **protocolList = class_copyProtocolList(cls, &count);
    for (unsigned int i=0; i<count; i++) {
        Protocol *myProtocal = protocolList[i];
        const char *protocolName = protocol_getName(myProtocal);
        NSLog(@"protocol---->%@", [NSString stringWithUTF8String:protocolName]);
        [arr addObject:[NSString stringWithUTF8String:protocolName]];
    }
    return arr;
}


@end
