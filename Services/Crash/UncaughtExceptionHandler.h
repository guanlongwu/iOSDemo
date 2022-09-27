//
//  UncaughtExceptionHandler.h
//  YYTool
//
//  Created by wugl on 2022/8/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UncaughtExceptionHandler : NSObject

+ (void)installUncaughtExceptionHandler;

@end

NS_ASSUME_NONNULL_END
