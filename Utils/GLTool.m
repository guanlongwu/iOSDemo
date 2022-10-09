//
//  GLTool.m
//  YYTool
//
//  Created by wugl on 2022/6/7.
//

#import "GLTool.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

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



#pragma mark - UI

+ (UIWindow *)window
{
    UIWindow *window = nil;
    if ([[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(window)]) {
        window = [[[UIApplication sharedApplication] delegate] window];
    } else {
        window = [UIApplication sharedApplication].windows.firstObject;
        if (![window isKeyWindow]) {
            UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
            if (CGRectEqualToRect(keyWindow.bounds, [UIScreen mainScreen].bounds)) {
                window = keyWindow;
            }
        }
    }
    
    return window;
}

//获取当前屏幕显示的viewcontroller
+ (UIViewController *)getCurrentVC
{
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    UIViewController *currentVC = [self getCurrentVCFrom:rootViewController];
    
    return currentVC;
}

+ (UIViewController *)getCurrentVCFrom:(UIViewController *)rootVC
{
    UIViewController *currentVC;
    
    if ([rootVC presentedViewController]) {
        // 视图是被presented出来的
        rootVC = [rootVC presentedViewController];
    }

    if ([rootVC isKindOfClass:[UITabBarController class]]) {
        // 根视图为UITabBarController
        currentVC = [self getCurrentVCFrom:[(UITabBarController *)rootVC selectedViewController]];
    } else if ([rootVC isKindOfClass:[UINavigationController class]]){
        // 根视图为UINavigationController
        currentVC = [self getCurrentVCFrom:[(UINavigationController *)rootVC visibleViewController]];
    } else {
        // 根视图为非导航类
        currentVC = rootVC;
    }
    
    return currentVC;
}

+ (UIViewController *)findCurrentShowingViewController
{
    //获得当前活动窗口的根视图
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *currentShowingVC = [self findCurrentShowingViewControllerFrom:vc];
    return currentShowingVC;
}

//注意考虑几种特殊情况：①A present B, B present C，参数vc为A时候的情况
/* 完整的描述请参见文件头部 */
+ (UIViewController *)findCurrentShowingViewControllerFrom:(UIViewController *)vc
{
    //方法1：递归方法 Recursive method
    UIViewController *currentShowingVC;
    if ([vc presentedViewController]) { //注要优先判断vc是否有弹出其他视图，如有则当前显示的视图肯定是在那上面
        // 当前视图是被presented出来的
        UIViewController *nextRootVC = [vc presentedViewController];
        currentShowingVC = [self findCurrentShowingViewControllerFrom:nextRootVC];
        
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        // 根视图为UITabBarController
        UIViewController *nextRootVC = [(UITabBarController *)vc selectedViewController];
        currentShowingVC = [self findCurrentShowingViewControllerFrom:nextRootVC];
        
    } else if ([vc isKindOfClass:[UINavigationController class]]){
        // 根视图为UINavigationController
        UIViewController *nextRootVC = [(UINavigationController *)vc visibleViewController];
        currentShowingVC = [self findCurrentShowingViewControllerFrom:nextRootVC];
        
    } else {
        // 根视图为非导航类
        currentShowingVC = vc;
    }
    
    return currentShowingVC;
    
    /*
    //方法2：遍历方法
    while (1)
    {
        if (vc.presentedViewController) {
            vc = vc.presentedViewController;
            
        } else if ([vc isKindOfClass:[UITabBarController class]]) {
            vc = ((UITabBarController*)vc).selectedViewController;
            
        } else if ([vc isKindOfClass:[UINavigationController class]]) {
            vc = ((UINavigationController*)vc).visibleViewController;
            
        //} else if (vc.childViewControllers.count > 0) {
        //    //如果是普通控制器，找childViewControllers最后一个
        //    vc = [vc.childViewControllers lastObject];
        } else {
            break;
        }
    }
    return vc;
    //*/
}


@end
