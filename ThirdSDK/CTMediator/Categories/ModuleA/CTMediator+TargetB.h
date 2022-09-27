//
//  CTMediator+TargetB.h
//  YYTool
//
//  Created by wugl on 2022/6/17.
//

#import "CTMediator.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTMediator (TargetB)

- (void)B_presentImage:(UIImage *)image;

- (void)B_showAlertWithMessage:(NSString *)message cancelAction:(void(^)(NSDictionary *info))cancelAction confirmAction:(void(^)(NSDictionary *info))confirmAction;

@end

NS_ASSUME_NONNULL_END
