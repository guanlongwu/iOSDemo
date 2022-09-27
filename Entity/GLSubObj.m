//
//  GLSubObj.m
//  YYTool
//
//  Created by wugl on 2022/6/7.
//

#import "GLSubObj.h"

@interface GLSubObj ()
@property (nonatomic, copy) NSString *desc;
@end

@implementation GLSubObj

#pragma mark - init/dealloc 不要调用 setter

- (instancetype)init
{
    if (self = [super init]) {
        NSLog(@"sub obj init");
        self.desc = @"sub desc";
    }
    return self;
}

- (void)setTitle:(NSString *)title
{
    NSLog(@"GLSubObj setTitle : %@", title);
    [super setTitle:title];
    
    NSString *copyString = [NSString stringWithString:self.desc];       // crash
    NSLog(@"sub obj copyString : %@", copyString);
}

- (void)run
{
    NSLog(@"sub obj desc:%@", self.desc);
}

- (void)dealloc
{
    NSLog(@"sub dealloc");
    _desc = nil;
}


#pragma mark - 

//- (void)up
//{
//    NSLog(@"sub obj up!");
//}

- (void)down
{
    NSLog(@"sub obj down!");
}

#pragma mark - method swizzling

static void gl_methodSwizzle(Class oriCls, SEL oriSel, Class swizzleCls, SEL swizzleSel)
{
    Method oriMethod = class_getInstanceMethod(oriCls, oriSel);
    Method swizzleMethod = class_getInstanceMethod(swizzleCls, swizzleSel);
    
    // 直接交换method会有风险：如果swizzle方法在这个类中找不到，就会去父类找，如果父类找到了，就会将父类的方法进行替换，影响了父类的方法
//    method_exchangeImplementations(oriMethod, swizzleMethod);
    
    // 下面这个方法，会先给这个类添加  swizzle方法，如果添加成功，则进行 oriSel 方法和 swizzleSel 方法的交换
    // 如果添加 swizzle 方法失败，则说明这个类 本来就有 swizzle 方法，不需要添加，进行 method 交换就好
    BOOL success = class_addMethod(oriCls, oriSel, method_getImplementation(swizzleMethod), method_getTypeEncoding(swizzleMethod));
    if (success) {
        /// 给原类添加 要混写的方法实现IMP
        class_replaceMethod(swizzleCls, swizzleSel, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
    }
    else {
        method_exchangeImplementations(oriMethod, swizzleMethod);
    }
}

+ (void)load
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
//        gl_methodSwizzle([GLSubObj class], @selector(up), [GLSubObj class], @selector(down));
    });
}

@end
