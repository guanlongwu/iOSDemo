//
//  MsgForwardAction.m
//  YYTool
//
//  Created by wugl on 2022/7/14.
//

#import "MsgForwardAction.h"
#import "GLObject.h"
#import "GLSubObj.h"
#import <objc/message.h>

@interface MsgForwardAction ()
@property (nonatomic, strong) GLObject *strongObj, *strongObj2;
@property (nonatomic, strong) UIButton *myBtn;

@end

@implementation MsgForwardAction

- (void)doWork
{
    [self _objcMsgSend];
    
    [self _testMethodSwizzle];
    
    [self _testCrashGuard];
}

#pragma mark - message 传递机制

- (void)_objcMsgSend
{
    id obj = [self performSelector:@selector(run)];
    NSLog(@"");
}

/// 动态方法解析
+ (BOOL)resolveInstanceMethod:(SEL)sel
{
    if (sel == @selector(run)) {
//        class_addMethod(self, sel, (IMP)runIMP, "v@:");
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}

id runIMP(id obj, SEL _cmd)
{
    NSLog(@"run  --  obj : %@, sel:%@", obj, NSStringFromSelector(_cmd));
    
    return [GLObject new];
}


/// 备用消息接收者  -- 快速消息转发
- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if (aSelector == @selector(run)) {
        return nil;//self.strongObj;
    }
    return [super forwardingTargetForSelector:aSelector];
}

- (GLObject *)strongObj
{
    if (!_strongObj) {
        _strongObj = [GLObject new];
    }
    return _strongObj;
}



/// 消息转发（慢速）
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if (aSelector == @selector(run)) {
        return [NSMethodSignature signatureWithObjCTypes:"@@:"];
    }
    return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    SEL sel = anInvocation.selector;
    id target = anInvocation.target;
    
    if (sel == @selector(run)) {
        if ([self.strongObj respondsToSelector:sel]) {
            [anInvocation invokeWithTarget:self.strongObj];
        }
    }
    else {
        [super forwardInvocation:anInvocation];
    }
}

/// 触发一次 消息转发：调用_objc_msgForward  这个IMP
static IMP _ATH_GetMsgForward(const char *methodTypes) {
    IMP msgForwardIMP = _objc_msgForward;
#if !defined(__arm64__)
    if (methodTypes[0] == '{') {
        NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:methodTypes];
        if ([methodSignature.debugDescription rangeOfString:@"is special struct return? YES"].location != NSNotFound) {
            msgForwardIMP = (IMP)_objc_msgForward_stret;
        }
    }
#endif
    return msgForwardIMP;
}

static void ATH_NSBlock_hookOnces() {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = NSClassFromString(@"NSObject");
        //forwardingTargetForSelector
//        {
//            SEL selector = @selector(forwardingTargetForSelector:);
//            Method method = class_getInstanceMethod([NSObject class], selector);
//            BOOL success = class_addMethod(cls, selector, (IMP)ath_block_forwardingTarget, method_getTypeEncoding(method));
//            if (!success) {
//                class_replaceMethod(cls, selector, (IMP)ath_block_forwardingTarget, method_getTypeEncoding(method));
//            }
//        }
        //methodSignature
        {
            SEL selector = @selector(methodSignatureForSelector:);
            Method method = class_getInstanceMethod([NSObject class], selector);
            BOOL success = class_addMethod(cls, selector, (IMP)ath_block_methodSignatureForSelector, method_getTypeEncoding(method));
            if (!success) {
                class_replaceMethod(cls, selector, (IMP)ath_block_methodSignatureForSelector, method_getTypeEncoding(method));
            }
        }
        //forwardInvocation
        {
            SEL selector = @selector(forwardInvocation:);
            Method method = class_getInstanceMethod([NSObject class], selector);
            BOOL success = class_addMethod(cls, selector, (IMP)ath_block_forwardInvocation, method_getTypeEncoding(method));
            if (!success) {
                class_replaceMethod(cls, selector, (IMP)ath_block_forwardInvocation, method_getTypeEncoding(method));
            }
        }
    });
}

id ath_block_forwardingTarget(id self, SEL _cmd, SEL aSelector)
{
    NSLog(@"wugl block forwardingTarget. selector:%@", NSStringFromSelector(aSelector));
    return nil;
}

static void ath_block_forwardInvocation(id self, SEL _cmd, NSInvocation *invocation)
{
    NSLog(@"wugl block forwardInvocation. selector:%@. target:%@", NSStringFromSelector(invocation.selector), invocation.target);
}

NSMethodSignature *ath_block_methodSignatureForSelector(id self, SEL _cmd, SEL aSelector)
{
    NSLog(@"wugl block methodSignature. selector:%@", NSStringFromSelector(aSelector));
    return [NSMethodSignature signatureWithObjCTypes:"@@:"];
}



#pragma mark - method swizzle

- (void)_testMethodSwizzle
{
//    [GLSubObj eat];
    
//    GLSubObj *obj = [GLSubObj new];
//    [obj performSelector:@selector(up)];  // down
////    [obj performSelector:@selector(down)];    // up
//
//    NSArray <NSString *>* methods = [GLTool methodsForClass:GLSubObj.class];
//    NSLog(@"sub methods : %@", methods);
//
//    methods = [GLTool methodsForClass:GLBaseObj.class];
//    NSLog(@"base methods : %@", methods);
//
//    NSLog(@"end");
//    GLBaseObj *obj = [GLBaseObj new];
//    [obj performSelector:@selector(up)];
//    [obj performSelector:@selector(down)];  // crash
    
}

#pragma mark - crash guard

- (void)_testCrashGuard
{
    //实例化一个button,未实现其方法
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(50, 100, 200, 100);
    button.backgroundColor = [UIColor blueColor];
    [button setTitle:@"消息转发" forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(doSomething)
     forControlEvents:UIControlEventTouchUpInside];
    [self.vc.view addSubview:button];
    self.myBtn = button;
}

@end
