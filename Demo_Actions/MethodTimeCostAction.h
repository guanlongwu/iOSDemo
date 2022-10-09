//
//  MethodTimeCostAction.h
//  iOSDemo
//
//  Created by wugl on 2022/9/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MethodTimeCostAction : NSObject

- (void)doWork;

+ (void)start;

+ (void)stop;

@end

NS_ASSUME_NONNULL_END
