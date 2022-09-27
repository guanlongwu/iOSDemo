//
//  NSObject+DeallocBlock.h
//  YYInterview
//
//  Created by wugl on 2022/5/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^DeallocBlock)(__unsafe_unretained NSObject *target);

@interface NSObject (DeallocBlock)

- (void)addDeallocBlock:(DeallocBlock)block;

@end

NS_ASSUME_NONNULL_END
