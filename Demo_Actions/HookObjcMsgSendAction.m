//
//  HookObjcMsgSendAction.m
//  YYTool
//
//  Created by wugl on 2022/9/15.
//

#import "HookObjcMsgSendAction.h"
#import "TPMainVC.h"
#import "TimeProfiler.h"
#import "TPModel.h"
#import "TPRecordHierarchyModel.h"
#import "GLCrashSignalExceptionHandler.h"
#import "GLUncaughtExceptionHandler.h"
#import "GLCrashMachExceptionHandler.h"
#import "GLTool.h"

@implementation HookObjcMsgSendAction

- (void)doWork
{
    
//    [GLUncaughtExceptionHandler registerHandler];
//    [GLCrashSignalExceptionHandler registerHandler];
//    [GLCrashMachExceptionHandler registerHandler];
    
    TPMainVC *vc = [[TPMainVC alloc] init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [[GLTool findCurrentShowingViewController] presentViewController:vc animated:YES completion:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSLog(@"\n\n\n ==== 开始统计 ==== \n\n\n");

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showAlert) name:TPTimeProfilerProcessedDataNotification object:nil];
        
        [[TimeProfiler shareInstance] TPStartTrace:"hook objc_msgSend"];
        
        [self test1];
        [self test2];
        [self test3];
        
        [[TimeProfiler shareInstance] TPStopTrace];
        
        NSLog(@"\n\n\n ==== 结束统计 ==== \n\n\n");
    });
    
}

- (void)showAlert
{
    NSMutableArray<TPModel *> *modelArr = [TimeProfiler shareInstance].modelArr;
    NSMutableArray <NSArray *> *showArr = [NSMutableArray array];
    [modelArr enumerateObjectsUsingBlock:^(TPModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray <TPRecordHierarchyModel *>*costTimeSortMethodRecord = obj.costTimeSortMethodRecord;
        NSMutableArray <NSString *> *subArr = [NSMutableArray array];
        [costTimeSortMethodRecord enumerateObjectsUsingBlock:^(TPRecordHierarchyModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            Class cls = obj.rootMethod.cls;
            SEL sel = obj.rootMethod.sel;
            uint64_t costTime = obj.rootMethod.costTime;
            NSString *str = [NSString stringWithFormat:@"\n====<cls:%@>,<sel:%@>,<costTime:%@>====\n", NSStringFromClass(cls), NSStringFromSelector(sel), @(costTime)];
            [subArr addObject:str];
        }];
        [showArr addObject:subArr];
    }];
    NSLog(@"%@", showArr);
}

#pragma mark - func

- (void)test1
{
    static int64_t value = 0;
    for (int64_t i=0; i<9999999; i++) {
        value += i;
    }
}

- (void)test2
{
    static int64_t value = 0;
    for (int64_t i=0; i<999999999; i++) {
        value += i;
    }
}

- (void)test3
{
    static int64_t value = 0;
    for (int64_t i=0; i<99999999; i++) {
        value += i;
    }
}

@end
