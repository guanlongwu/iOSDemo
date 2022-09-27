//
//  RunLoopAction.h
//  YYTool
//
//  Created by wugl on 2022/7/14.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RunLoopAction : NSObject
@property (nonatomic, weak) UIViewController *vc;

- (void)doWork;

@end

NS_ASSUME_NONNULL_END
