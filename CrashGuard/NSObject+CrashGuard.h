//
//  NSObject+CrashGuard.h
//  YYTool
//
//  Created by wugl on 2022/6/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (CrashGuard)

#pragma mark - hook 类方法

+ (void)eat;

+ (void)gl_eat;

@end

NS_ASSUME_NONNULL_END
