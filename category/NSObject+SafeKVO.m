//
//  NSObject+SafeKVO.m
//  YYInterview
//
//  Created by wugl on 2022/5/25.
//

#import "NSObject+SafeKVO.h"
#import "NSObject+DeallocBlock.h"

@implementation NSObject (SafeKVO)

- (void)safe_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context
{
    [self addObserver:observer forKeyPath:keyPath options:options context:context];
    __weak typeof(self) weakSelf = self;
    [self addDeallocBlock:^(NSObject *__unsafe_unretained  _Nonnull target) {
        [weakSelf removeObserver:observer forKeyPath:keyPath context:context];
    }];
}

@end
