//
//  NSObject+WeakProperty.m
//  YYInterview
//
//  Created by wugl on 2022/5/25.
//

#import "NSObject+WeakProperty.h"
#import "NSObject+DeallocBlock.h"
#import <objc/runtime.h>

void objc_setWeakAssociatedObject(id _Nonnull object, const void * _Nonnull key, id _Nullable value) {
    if (value) {
        //__weak typeof(object) weakObj = object;
        [value addDeallocBlock:^(NSObject *__unsafe_unretained  _Nonnull target) {
            objc_setAssociatedObject(object, key, nil, OBJC_ASSOCIATION_ASSIGN); // clear association
        }];
    }
    objc_setAssociatedObject(object, key, value, OBJC_ASSOCIATION_ASSIGN); // call system imp
}

@implementation NSObject (WeakProperty)

@end
