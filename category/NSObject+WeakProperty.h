//
//  NSObject+WeakProperty.h
//  YYInterview
//
//  Created by wugl on 2022/5/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern void objc_setWeakAssociatedObject(id _Nonnull object, const void * _Nonnull key, id _Nullable value);

@interface NSObject (WeakProperty)

@end

NS_ASSUME_NONNULL_END
