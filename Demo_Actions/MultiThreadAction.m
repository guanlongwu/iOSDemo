//
//  MultiThreadAction.m
//  YYTool
//
//  Created by wugl on 2022/7/25.
//

#import "MultiThreadAction.h"

@interface MultiItem : NSObject
@property (nonatomic, copy) NSString *uid;
@end

@implementation MultiItem

+ (MultiItem *)itemWithUid:(NSString *)uid
{
    MultiItem *item = [MultiItem new];
    item.uid = uid;
    return item;
}

@end

@interface MultiThreadAction ()
@property (nonatomic, strong) NSMutableArray <MultiItem *>*arr;
@end

@implementation MultiThreadAction

- (void)doWork
{
//    [self _case1];
    [self _case2];
}

- (void)_case1
{
    self.arr = [@[
        [MultiItem itemWithUid:@"1"],
        [MultiItem itemWithUid:@"2"],
        [MultiItem itemWithUid:@"3"],
    ] mutableCopy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i=0; i<999999; i++) {
            NSArray *ids = [self.arr valueForKey:@"uid"];
            NSSet *set = [NSSet setWithArray:ids];
        }
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i=0; i<999999; i++) {
            MultiItem *last = [self.arr lastObject];
            [self.arr removeLastObject];
            [self.arr addObject:last];
        }
    });
}

- (void)_case2
{
    [self _getInfo:^(NSMutableArray *list) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0*NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for (int i=0; i<999999; i++) {
                MultiItem *last = [list lastObject];
                [list removeLastObject];
                [list addObject:last];
            }
        });
    }];
    
    for (int i=0; i<999999; i++) {

        NSArray *ids = [self.arr valueForKey:@"uid"];
        NSSet *set = [NSSet setWithArray:ids];
    }
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0*NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        for (int i=0; i<999999; i++) {
//
//        MultiItem *item = [self.arr lastObject];
//        NSLog(@"");
//        }
//    });
}

- (void)_getInfo:(void(^)(NSMutableArray *list))completion
{
    self.arr = [@[
        [MultiItem itemWithUid:@"1"],
        [MultiItem itemWithUid:@"2"],
        [MultiItem itemWithUid:@"3"],
    ] mutableCopy];
    if (completion) {
        completion(self.arr);
    }
}


@end
