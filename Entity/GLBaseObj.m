//
//  GLBaseObj.m
//  YYTool
//
//  Created by wugl on 2022/6/7.
//

#import "GLBaseObj.h"

@implementation GLBaseObj

#pragma mark - init/dealloc 不要调用 setter

- (instancetype)init
{
    if (self = [super init]) {
        NSLog(@"base obj init");
        self.title = @"base title";
    }
    return self;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    NSLog(@"GLBaseObj setTitle : %@", title);
}

- (void)dealloc
{
    NSLog(@"base dealloc");
    self.title = nil;
}


#pragma mark -

- (void)up
{
    NSLog(@"base obj up!");
}

@end
