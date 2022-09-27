//
//  GCDAction.m
//  YYTool
//
//  Created by wugl on 2022/7/25.
//

#import "GCDAction.h"

typedef void (^MEApiGroupStrategyFinish)(BOOL timeout);

@interface GCDAction ()

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@property (nonatomic, strong) dispatch_group_t group;
@property (nonatomic, strong) dispatch_queue_t globalQueue;

@end

@implementation GCDAction

- (instancetype)init
{
    if (self = [super init]) {
        _serialQueue = dispatch_queue_create("com.gcd.serialQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)doWork
{
//    [self _gcd1];
    [self _gcd2];
}

#pragma mark - 同步/异步、串行/并行 （GCD输出顺序）

- (void)_gcd1
{
    dispatch_async(self.serialQueue, ^{
        NSLog(@"--0--");

        [self _action2];
        
        NSLog(@"block");
        
        NSLog(@"--2--");
    });
}

- (void)_action2
{
    dispatch_async(self.serialQueue, ^{
        NSLog(@"--1--");

        [self _action3:^(BOOL result) {
            NSLog(@"--4--");

        }];
        
        NSLog(@"--5--");

    });
}

- (void)_action3:(void(^)(BOOL result))completion
{
    dispatch_async(self.serialQueue, ^{
        NSLog(@"--6--");

        if (completion) {
            completion(YES);
        }
    });
}

// 0 finish 2 1 5 3  4


#pragma mark - GCD输出顺序 demo2

- (void)doWork1
{
    [self _action:^(BOOL result) {
        NSLog(@"finish");
    }];
}

- (void)_action:(void(^)(BOOL result))completion
{
    dispatch_async(self.serialQueue, ^{
        [self _busyAction:@"0"];
        
        [self _action2];
        
        if (completion) {
            completion(YES);
        }
        
        [self _busyAction:@"2"];
    });
}

- (void)_busyAction:(NSString *)tag
{
    NSLog(@"--start--:%@", tag);
//    static int inc = 0;
//    for (int i=0; i<999999999; i++) {
//        inc ++;
//    }
//    NSLog(@"--end--:%@", tag);
//    inc = 0;
}


#pragma mark - GCD 组

- (void)_gcd2
{
    self.group = dispatch_group_create();
    self.globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    void(^asyncBlock)(void) = ^{
        [self _asyncTask:^{
            [self setTaskComplete];
            [self setTaskComplete];
        }];
    };
    [self addTaskBlock:^{
        asyncBlock();
    }];
    [self setAllTasksFinish:^(BOOL timeout) {
        NSLog(@"");
    }];
}

- (void)_asyncTask:(void(^)(void))completion
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        completion();
    });
}

/// 添加异步任务
- (void)addTaskBlock:(dispatch_block_t)taskBlock
{
    dispatch_group_enter(self.group);
    dispatch_group_async(self.group, self.globalQueue, ^{
        if (taskBlock) {
            taskBlock();
        }
    });
}

/// 所有任务完成回调
- (void)setAllTasksFinish:(MEApiGroupStrategyFinish)finish
{
    dispatch_group_notify(self.group, dispatch_get_main_queue(), ^{
        if (finish) {
            finish(NO);
        }
    });
    
    // 设置超时时间
    dispatch_async(self.globalQueue, ^{
        NSInteger res = dispatch_group_wait(self.group, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)));
        if (0 != res) {
            // 超时了还未处理完group事件
            dispatch_async(dispatch_get_main_queue(), ^{
                if (finish) {
                    finish(YES);
                }
            });
        }
    });
}

/// 设置任务完成
- (void)setTaskComplete
{
    if (self.group) {
        // 防止过度出组引发crash
        dispatch_group_leave(self.group);
    }
}


@end

