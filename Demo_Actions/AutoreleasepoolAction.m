//
//  AutoreleasepoolAction.m
//  YYTool
//
//  Created by wugl on 2022/7/14.
//

#import "AutoreleasepoolAction.h"

#import <mach/mach.h>
double getMemoryUsage(void) {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self_, TASK_BASIC_INFO, (task_info_t)&info, &size);
    double memoryUsageInMB = kerr == KERN_SUCCESS ? (info.resident_size / 1024.0 / 1024.0) : 0.0;
    return memoryUsageInMB;
}


@interface AutoreleasepoolAction ()

@end


@implementation AutoreleasepoolAction {
    CFRunLoopObserverRef runLoopObserver;
}

- (void)doWork
{
    [self _testAutoreleasepool];
}

#pragma mark - autoreleasepool

- (void)_testAutoreleasepool
{
//    int lagerNum = 800000;
//    for(int i = 0; i <lagerNum; i++) {
//       NSNumber *num = [NSNumber numberWithInt:i];
//       NSString *str = [NSString stringWithFormat:@"%d ", i];
//       [NSString stringWithFormat:@"%@%@", num, str];
//    }
//    return;
    
    /*
    NSLog(@"--start--");
    int type = 3;
    if (0 == type) {
        NSLog(@"--sub start 0--");
        for (int i=0; i<999999; i++) {
            GLObject *obj = [GLObject new];
            obj.name = [NSString stringWithFormat:@"%d", i];
        }
        NSLog(@"--sub end 0--");
    }
    else if (1 == type) {
        NSLog(@"--sub start 1--");
        for (int i=0; i<999999; i++) {
            @autoreleasepool {
                GLObject *obj = [GLObject new];
                obj.name = [NSString stringWithFormat:@"%d", i];
            }
        }
        NSLog(@"--sub end 1--");
    }
    else if (2 == type) {
        NSLog(@"--sub start 2--");
        @autoreleasepool {
            for (int i=0; i<999999; i++) {
                if (i == 1 || i == 99998) {
                    NSLog(@"%d new", i);
                }
                GLObject *obj = [GLObject new];
                obj.name = [NSString stringWithFormat:@"%d", i];
            }
        }
        NSLog(@"--sub end 2--");
    }
    else {
        
        self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadAddRunLoopAction) object:nil];
        [self.thread start];
        
        [self performSelector:@selector(threadSelector) onThread:self.thread withObject:nil waitUntilDone:NO];
    }
    NSLog(@"--end--");
     */
    
    int64_t lagerNum = 900000;
    static BOOL isAutorelasepool;
    isAutorelasepool = !isAutorelasepool;
    
    if (isAutorelasepool) {
        NSLog(@"add autorelasepool");
        for (int i = 0; i < lagerNum; i++) {
            @autoreleasepool {
                NSNumber *num = [NSNumber numberWithInt:i];
                NSString *str = [NSString stringWithFormat:@"%d ", i];
                [NSString stringWithFormat:@"%@%@", num, str];
                
//                GLObject *obj = [[GLObject alloc] init];
//                obj.name = @"i";
        
                if (i == lagerNum - 5) {  // 获取到快结束时候的内存
                    float memory = getMemoryUsage();
                    NSLog(@" 内存 --- %f",memory);
                }
            }
        }
    }
    else {
        
        NSLog(@"no autorelasepool");
        for(int i = 0; i <lagerNum; i++) {
           NSNumber *num = [NSNumber numberWithInt:i];
           NSString *str = [NSString stringWithFormat:@"%d ", i];
           [NSString stringWithFormat:@"%@%@", num, str];
            
//            GLObject *obj = [[GLObject alloc] init];
//            obj.name = @"i";
            if (i == lagerNum - 5) {  // 获取到快结束时候的内存
                float memory = getMemoryUsage();
                NSLog(@" 内存 --- %f",memory);
            }
        }
    }
    
}

- (void)threadAddRunLoopAction
{
    [[NSRunLoop currentRunLoop] addPort:[NSMachPort port] forMode:NSRunLoopCommonModes];
    [[NSRunLoop currentRunLoop] run];
}

- (void)threadSelector
{
    if (NULL == runLoopObserver) {
        [self addRunLoopObserver];
    }
    NSLog(@"__thread start --");
//            @autoreleasepool {
        for (int i=0; i<999999; i++) {
            if (i == 1 || i == 999998) {
                NSLog(@"%d new", i);
            }
            GLObject *obj = [GLObject new];
            obj.name = [NSString stringWithFormat:@"%d", i];
        }

    {
        GLObject *obj = [GLObject new];
        obj.name = @"kaixin";
    }

    {
        GLObject *obj = [GLObject new];
        obj.name = @"kuaile";
    }
//            }
    NSLog(@"__thread end --");
}

- (void)threadAction
{
    NSLog(@"----*****----");
}

#pragma mark - runloop observer

- (void)addRunLoopObserver {
    CFRunLoopObserverContext context = {0,(__bridge void *)self,NULL,NULL};
    runLoopObserver = CFRunLoopObserverCreate(kCFAllocatorDefault,kCFRunLoopAllActivities,YES,INT_MAX,&RunLoopObserverCallBack,&context);
    
    CFRunLoopAddObserver([[NSRunLoop currentRunLoop] getCFRunLoop], runLoopObserver, kCFRunLoopCommonModes);
}


static void RunLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void* info)
{
//    NSString* infoStringValue = [NSString stringWithFormat:@"%p",info];
    switch (activity) {
        case kCFRunLoopEntry:
            NSLog(@"observer: loop entry");
            break;
        case kCFRunLoopBeforeTimers:
            NSLog(@"observer: before timers");
            break;
        case kCFRunLoopBeforeSources:
            NSLog(@"observer: before sources");
            break;
        case kCFRunLoopBeforeWaiting: {
            NSLog(@"observer: before waiting");
        }
            break;
        case kCFRunLoopAfterWaiting:
            NSLog(@"observer: after waiting");
            break;
        case kCFRunLoopExit:
            NSLog(@"observer: exit");
            break;
        case kCFRunLoopAllActivities:
            NSLog(@"observer: all activities");
            break;
        default:
            break;
    }
}





@end
