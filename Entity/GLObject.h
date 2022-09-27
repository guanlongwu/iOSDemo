//
//  GLObject.h
//  YYInterview
//
//  Created by wugl on 2022/4/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YYToolType) {
    YYToolType_1 = 0,
    YYToolType_2 = 1
};

typedef void(^GLObjectBlock)(NSString *name);

@interface GLObject : NSObject <NSCopying>
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) YYToolType type;
@property (nonatomic, copy) GLObjectBlock block;

- (void)doWork;
@end


NS_ASSUME_NONNULL_END
