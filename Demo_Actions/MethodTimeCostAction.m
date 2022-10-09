//
//  MethodTimeCostAction.m
//  iOSDemo
//
//  Created by wugl on 2022/9/29.
//

#import "MethodTimeCostAction.h"
#include "MTHCallTraceCore.h"
#import "MTHCallTraceTimeCostModel.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

@interface MTimeCostVc : UIViewController

@end

@implementation MTimeCostVc

- (instancetype)init
{
    if (self = [super init]) {
        self.view.backgroundColor = [UIColor redColor];
    }
    return self;
}

@end



@implementation MethodTimeCostAction

- (void)doWork
{
    [MethodTimeCostAction start];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self action];
        
        [MethodTimeCostAction stop];
    });
    
}

- (void)action
{
    NSLog(@"start");
    
    [self test];
    static int64_t value = 0;
    for (int64_t i=0; i<9999999; i++) {
        value += i;
    }
    NSLog(@"stop");
}

- (void)test
{
    
    static int64_t value = 0;
    for (int64_t i=0; i<99999999; i++) {
        value += i;
    }
}


#pragma mark -

+ (void)start
{
    mth_calltraceStart();
}

+ (void)stop
{
    mth_calltraceStop();
    NSArray<MTHCallTraceTimeCostModel *> *records = [MethodTimeCostAction records];
    NSLog(@"\n=== timecost:\n%@\n", records);
}

+ (NSArray<MTHCallTraceTimeCostModel *> *)records {
    return [self recordsFromIndex:0];
}

+ (NSArray<MTHCallTraceTimeCostModel *> *)recordsFromIndex:(NSInteger)index {
    NSMutableArray<MTHCallTraceTimeCostModel *> *arr = @[].mutableCopy;
    int num = 0;
    mth_call_record *records = mth_getCallRecords(&num);
    if (index >= num) {
        return [arr copy];
    }

    for (int i = (int)index; i < num; ++i) {
        mth_call_record *record = &records[i];
        MTHCallTraceTimeCostModel *model = [MTHCallTraceTimeCostModel new];
        model.className = NSStringFromClass(record->cls);
        model.methodName = NSStringFromSelector(record->sel);
        model.isClassMethod = class_isMetaClass(record->cls);
        model.timeCostInMS = (double)record->cost * 1e-3;
        model.eventTime = record->event_time;
        model.callDepth = record->depth;
        [arr addObject:model];
    }
    return [arr copy];
}

@end
