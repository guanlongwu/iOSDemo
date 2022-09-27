//
//  DeallocOrderAction.m
//  YYTool
//
//  Created by wugl on 2022/7/14.
//

#import "DeallocOrderAction.h"
#import "GLObject.h"

@implementation DeallocOrderAction

- (void)doWork
{
    GLObject *obj0 = [[GLObject alloc] init];
    obj0.name = @"0";
    GLObject *obj1 = [[GLObject alloc] init];
    obj1.name = @"1";
    
    {
        GLObject *obj2 = [[GLObject alloc] init];
        obj2.name = @"2";
    }
    
    __weak GLObject *obj3 = [[GLObject alloc] init];
    obj3.name = @"3";
    
    GLObject *obj4 = [[GLObject alloc] init];
    __weak GLObject *obj5 = obj4;
    obj5.name = @"5";
}

@end
