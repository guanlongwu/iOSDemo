//
//  CTMediator.m
//  CTMediator
//
//  Created by casa on 16/3/13.
//  Copyright © 2016年 casa. All rights reserved.
//

#import "CTMediator.h"
#import <objc/runtime.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/message.h>

NSString * const kCTMediatorParamsKeySwiftTargetModuleName = @"kCTMediatorParamsKeySwiftTargetModuleName";

@interface CTMediator ()

@property (nonatomic, strong) NSMutableDictionary *cachedTarget;

@end

@implementation CTMediator

#pragma mark - public methods
+ (instancetype)sharedInstance
{
    static CTMediator *mediator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mediator = [[CTMediator alloc] init];
        [mediator cachedTarget]; // 同时把cachedTarget初始化，避免多线程重复初始化
    });
    return mediator;
}

/*
 scheme://[target]/[action]?[params]
 
 url sample:
 aaa://targetA/actionB?id=1234
 */

- (id)performActionWithUrl:(NSURL *)url completion:(void (^)(NSDictionary *))completion
{
    if (url == nil||![url isKindOfClass:[NSURL class]]) {
        return nil;
    }
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:url.absoluteString];
    // 遍历所有参数
    [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.value&&obj.name) {
            [params setObject:obj.value forKey:obj.name];
        }
    }];
    
    // 这里这么写主要是出于安全考虑，防止黑客通过远程方式调用本地模块。这里的做法足以应对绝大多数场景，如果要求更加严苛，也可以做更加复杂的安全逻辑。
    NSString *actionName = [url.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
    if ([actionName hasPrefix:@"native"]) {
        return @(NO);
    }
    
    // 这个demo针对URL的路由处理非常简单，就只是取对应的target名字和method名字，但这已经足以应对绝大部份需求。如果需要拓展，可以在这个方法调用之前加入完整的路由逻辑
    id result = [self performTarget:url.host action:actionName params:params shouldCacheTarget:NO];
    if (completion) {
        if (result) {
            completion(@{@"result":result});
        } else {
            completion(nil);
        }
    }
    return result;
}











- (void)gl_performTarget:(NSString *)targetName action:(NSString *)actionName
{
    Class class = NSClassFromString(targetName);
    SEL selector = NSSelectorFromString(actionName);
    
    
    [self gl_hookClass:class sel:selector];
    
    NSObject *target = [[class alloc] init];
    [target performSelector:selector];

}

- (void)gl_performTarget:(NSString *)targetName sel:(SEL)selector
{
    Class class = NSClassFromString(targetName);
    
    [self gl_hookClass:class sel:selector];
    
    NSObject *target = [[class alloc] init];
    [target performSelector:selector];

}



static IMP aspect_getMsgForwardIMP(NSObject *self, SEL selector) {
    IMP msgForwardIMP = _objc_msgForward;
#if !defined(__arm64__)
    // As an ugly internal runtime implementation detail in the 32bit runtime, we need to determine of the method we hook returns a struct or anything larger than id.
    // https://developer.apple.com/library/mac/documentation/DeveloperTools/Conceptual/LowLevelABI/000-Introduction/introduction.html
    // https://github.com/ReactiveCocoa/ReactiveCocoa/issues/783
    // http://infocenter.arm.com/help/topic/com.arm.doc.ihi0042e/IHI0042E_aapcs.pdf (Section 5.4)
    Method method = class_getInstanceMethod(self.class, selector);
    const char *encoding = method_getTypeEncoding(method);
    BOOL methodReturnsStructValue = encoding[0] == _C_STRUCT_B;
    if (methodReturnsStructValue) {
        @try {
            NSUInteger valueSize = 0;
            NSGetSizeAndAlignment(encoding, &valueSize, NULL);

            if (valueSize == 1 || valueSize == 2 || valueSize == 4 || valueSize == 8) {
                methodReturnsStructValue = NO;
            }
        } @catch (NSException *e) {}
    }
    if (methodReturnsStructValue) {
        msgForwardIMP = (IMP)_objc_msgForward_stret;
    }
#endif
    return msgForwardIMP;
}


static NSString *const AspectsForwardInvocationSelectorName = @"__aspects_forwardInvocation:";

- (void)gl_hookClass:(Class)klass sel:(SEL)selector
{
    // hook 消息转发方法 forwardInvocation
    IMP originalImplementation = class_replaceMethod(klass, @selector(forwardInvocation:), (IMP)__ASPECTS_ARE_BEING_CALLED__, "v@:@");
    if (originalImplementation) { // 如果替换成功了
        // 为这个类再添加一个 名字叫 __aspects_forwardInvocation: 的方法，实现用 originalImplementation。
        class_addMethod(klass, NSSelectorFromString(AspectsForwardInvocationSelectorName), originalImplementation, "v@:@");
    }
    
    
    // hook 原来的selector
    // 创建Method对象
    Method targetMethod = class_getInstanceMethod(klass, selector);
    // 获取方法实现 IMP
    IMP targetMethodIMP = method_getImplementation(targetMethod);
    
    
    // 得到方法 TypeEncoding
    const char *typeEncoding = method_getTypeEncoding(targetMethod);
    // 获取方法别名
    SEL aliasSelector = aspect_aliasForSelector(selector);

    // 如果 不能响应 aspect 别名方法
    if (![klass instancesRespondToSelector:aliasSelector]) {

        // 给kclass添加别名方法 实现用原函数实现
        __unused BOOL addedAlias = class_addMethod(klass, aliasSelector, targetMethodIMP, typeEncoding);
    }

    // We use forwardInvocation to hook in.
    // 替换klass的selector用_objc_msgForward替换
    // 将消息转发函数实现 替换 hook 原函数实现
    class_replaceMethod(klass, selector, aspect_getMsgForwardIMP(self, selector), typeEncoding);
}

static NSString *const AspectsMessagePrefix = @"aspects_";

static SEL aspect_aliasForSelector(SEL selector) {
    return NSSelectorFromString([AspectsMessagePrefix stringByAppendingFormat:@"_%@", NSStringFromSelector(selector)]);
}

static void __ASPECTS_ARE_BEING_CALLED__(__unsafe_unretained NSObject *self, SEL selector, NSInvocation *invocation)
{
//    // 获取 invocation 的SEL方法名
//    SEL originalSelector = invocation.selector;
//    // 拼接 别名方法 通过 SEL
//    SEL aliasSelector = aspect_aliasForSelector(invocation.selector);
//    // 替换invocation中的调用方法
//    invocation.selector = aliasSelector;
    
    
    
    
        
    
    NSInvocation *blockInvocation = [NSInvocation invocationWithMethodSignature:invocation.methodSignature];
    NSUInteger numberOfArguments = invocation.methodSignature.numberOfArguments;
    
    void *argBuf = NULL;
    for (NSUInteger idx = 2; idx < numberOfArguments; idx++) {
        const char *type = [invocation.methodSignature getArgumentTypeAtIndex:idx];
        NSUInteger argSize;
        NSGetSizeAndAlignment(type, &argSize, NULL);
        
        if (!(argBuf = reallocf(argBuf, argSize))) {
            NSLog(@"Failed to allocate memory for block invocation.");
            return;
        }
        
        [invocation getArgument:argBuf atIndex:idx];
        [blockInvocation setArgument:argBuf atIndex:idx];
    }
    
    
//    NSString *targetClassString = [NSString stringWithFormat:@"Target_%@", @"A"];
//    Class targetClass = NSClassFromString(targetClassString);
//    NSObject *target = [[targetClass alloc] init];
    
    blockInvocation.target = self;
    SEL aliasSelector = aspect_aliasForSelector(invocation.selector);
    blockInvocation.selector = aliasSelector;
    
    [blockInvocation invoke];

    
}

void cacheTarget(NSObject *target)
{
    if (!target) {
        return;
    }
    static NSMutableArray *targetList = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        targetList = [NSMutableArray array];
    });
    [targetList addObject:target];
}












- (id)performTarget:(NSString *)targetName action:(NSString *)actionName params:(NSDictionary *)params shouldCacheTarget:(BOOL)shouldCacheTarget
{
    if (targetName == nil || actionName == nil) {
        return nil;
    }
    
    NSString *swiftModuleName = params[kCTMediatorParamsKeySwiftTargetModuleName];
    
    // generate target
    NSString *targetClassString = nil;
    if (swiftModuleName.length > 0) {
        targetClassString = [NSString stringWithFormat:@"%@.Target_%@", swiftModuleName, targetName];
    } else {
        targetClassString = [NSString stringWithFormat:@"Target_%@", targetName];
    }
    NSObject *target = [self safeFetchCachedTarget:targetClassString];
    if (target == nil) {
        Class targetClass = NSClassFromString(targetClassString);
        target = [[targetClass alloc] init];
    }

    // generate action
    NSString *actionString = [NSString stringWithFormat:@"Action_%@:", actionName];
    SEL action = NSSelectorFromString(actionString);
    
    if (target == nil) {
        // 这里是处理无响应请求的地方之一，这个demo做得比较简单，如果没有可以响应的target，就直接return了。实际开发过程中是可以事先给一个固定的target专门用于在这个时候顶上，然后处理这种请求的
        [self NoTargetActionResponseWithTargetString:targetClassString selectorString:actionString originParams:params];
        return nil;
    }
    
    if (shouldCacheTarget) {
        [self safeSetCachedTarget:target key:targetClassString];
    }

    if ([target respondsToSelector:action]) {
        return [self safePerformAction:action target:target params:params];
    } else {
        // 这里是处理无响应请求的地方，如果无响应，则尝试调用对应target的notFound方法统一处理
        SEL action = NSSelectorFromString(@"notFound:");
        if ([target respondsToSelector:action]) {
            return [self safePerformAction:action target:target params:params];
        } else {
            // 这里也是处理无响应请求的地方，在notFound都没有的时候，这个demo是直接return了。实际开发过程中，可以用前面提到的固定的target顶上的。
            [self NoTargetActionResponseWithTargetString:targetClassString selectorString:actionString originParams:params];
            @synchronized (self) {
                [self.cachedTarget removeObjectForKey:targetClassString];
            }
            return nil;
        }
    }
}

- (void)releaseCachedTargetWithFullTargetName:(NSString *)fullTargetName
{
    /*
     fullTargetName在oc环境下，就是Target_XXXX。要带上Target_前缀。在swift环境下，就是XXXModule.Target_YYY。不光要带上Target_前缀，还要带上模块名。
     */
    if (fullTargetName == nil) {
        return;
    }
    @synchronized (self) {
        [self.cachedTarget removeObjectForKey:fullTargetName];
    }
}

#pragma mark - private methods
- (void)NoTargetActionResponseWithTargetString:(NSString *)targetString selectorString:(NSString *)selectorString originParams:(NSDictionary *)originParams
{
    SEL action = NSSelectorFromString(@"Action_response:");
    NSObject *target = [[NSClassFromString(@"Target_NoTargetAction") alloc] init];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"originParams"] = originParams;
    params[@"targetString"] = targetString;
    params[@"selectorString"] = selectorString;
    
    [self safePerformAction:action target:target params:params];
}

- (id)safePerformAction:(SEL)action target:(NSObject *)target params:(NSDictionary *)params
{
    NSMethodSignature* methodSig = [target methodSignatureForSelector:action];
    if(methodSig == nil) {
        return nil;
    }
    const char* retType = [methodSig methodReturnType];

    if (strcmp(retType, @encode(void)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        return nil;
    }

    if (strcmp(retType, @encode(NSInteger)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        NSInteger result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }

    if (strcmp(retType, @encode(BOOL)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        BOOL result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }

    if (strcmp(retType, @encode(CGFloat)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        CGFloat result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }

    if (strcmp(retType, @encode(NSUInteger)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        NSUInteger result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [target performSelector:action withObject:params];
#pragma clang diagnostic pop
}

#pragma mark - getters and setters
- (NSMutableDictionary *)cachedTarget
{
    if (_cachedTarget == nil) {
        _cachedTarget = [[NSMutableDictionary alloc] init];
    }
    return _cachedTarget;
}

- (NSObject *)safeFetchCachedTarget:(NSString *)key {
    @synchronized (self) {
        return self.cachedTarget[key];
    }
}

- (void)safeSetCachedTarget:(NSObject *)target key:(NSString *)key {
    @synchronized (self) {
        self.cachedTarget[key] = target;
    }
}






- (NSString *)targetString
{
    return @"";
}

#pragma mark - method forward

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSString *targetString = [self targetString];
    if (targetString.length == 0) {
        return nil;
    }
    Class targetCls = NSClassFromString(targetString);
    if (!targetCls) {
        return nil;
    }
    
    NSObject *target = [[targetCls alloc] init];
    
    NSMethodSignature *sig = [target methodSignatureForSelector:aSelector];
    if (sig) {
        return sig;
    }
    
//    if (aSelector == @selector(CTMediator_showAlertWithMessage:cancelAction:confirmAction:)) {
//        NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:"v@:@@@"];
//        return sig;
//    }
//    else if (aSelector == @selector(CTMediator_presentImage:)) {
//        NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:"v@:@"];
//        return sig;
//    }
    return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    NSString *targetString = [self targetString];
    if (targetString.length == 0) {
        return;
    }
    Class targetCls = NSClassFromString(targetString);
    if (!targetCls) {
        return;
    }
    
    NSInvocation *blockInvocation = [NSInvocation invocationWithMethodSignature:invocation.methodSignature];
    NSUInteger numberOfArguments = invocation.methodSignature.numberOfArguments;
    
    void *argBuf = NULL;
    for (NSUInteger idx = 2; idx < numberOfArguments; idx++) {
        const char *type = [invocation.methodSignature getArgumentTypeAtIndex:idx];
        NSUInteger argSize;
        NSGetSizeAndAlignment(type, &argSize, NULL);
        
        if (!(argBuf = reallocf(argBuf, argSize))) {
            NSLog(@"Failed to allocate memory for block invocation.");
            return;
        }
        
        [invocation getArgument:argBuf atIndex:idx];
        [blockInvocation setArgument:argBuf atIndex:idx];
    }
    
    NSObject *target = [[targetCls alloc] init];
    blockInvocation.target = target;
    blockInvocation.selector = invocation.selector;
    
    
    if (![target respondsToSelector:invocation.selector]) {
        NSLog(@"");
        return;
    }
    
    [blockInvocation invoke];
}



@end

CTMediator* _Nonnull CT(void){
    return [CTMediator sharedInstance];
};
