//
//  GLTool.h
//  YYTool
//
//  Created by wugl on 2022/6/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GLTool : NSObject

+ (NSArray <NSString *>*)propertiesForClass:(Class)cls;

+ (NSArray <NSString *>*)methodsForClass:(Class)cls;

+ (NSArray <NSString *>*)ivarsForClass:(Class)cls;

+ (NSArray <NSString *>*)protocolsForClass:(Class)cls;

@end

NS_ASSUME_NONNULL_END
