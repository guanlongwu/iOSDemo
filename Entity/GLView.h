//
//  GLView.h
//  YYInterview
//
//  Created by wugl on 2022/4/27.
//

#import <UIKit/UIKit.h>
#import "GLObject.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kNotifyName;

@interface GLView : UIView
@property (nonatomic, strong) GLObject *obj;
@end

NS_ASSUME_NONNULL_END
