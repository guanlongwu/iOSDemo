//
//  RunLoopAction.m
//  YYTool
//
//  Created by wugl on 2022/7/14.
//

#import "RunLoopAction.h"
#import "GLObject.h"
#import "NSThread+YYAdd.h"

@interface RunLoopAction ()
@property (nonatomic, strong) NSMutableArray <dispatch_block_t> *blocks;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataSet;
@property (nonatomic, strong) GLObject *myObj;

@property (nonatomic, strong) NSThread *thread, *thread2;
@property (nonatomic, assign) BOOL threadBlock, threadBlock2;
@end

@implementation RunLoopAction {
    CFRunLoopObserverRef runLoopObserver;
}

- (void)dealloc
{
    CFRunLoopRemoveObserver([[NSRunLoop currentRunLoop] getCFRunLoop], runLoopObserver, kCFRunLoopCommonModes);
}

- (void)doWork
{
    [self addRunLoopObserver];
    
//    [self _testMultiThread];
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
    RunLoopAction *vc = (__bridge RunLoopAction *)info;
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
            [vc _runBlock];
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

- (void)_addBlock:(dispatch_block_t)block
{
    if (!block) {
        return;
    }
    @synchronized (self.blocks) {
        [self.blocks addObject:block];
    }
}

- (void)_runBlock
{
    @synchronized (self.blocks) {
        [self.blocks enumerateObjectsUsingBlock:^(dispatch_block_t  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj();
        }];
        [self.blocks removeAllObjects];
    }
}

- (void)_busyAction
{
    NSLog(@"--start--");
    static int inc = 0;
    for (int i=0; i<999999999; i++) {
        inc ++;
    }
    NSLog(@"--end--");
    inc = 0;
}

#pragma mark - uitableview

- (void)_setTable {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 500, 500) style:UITableViewStylePlain];
    [self.vc.view addSubview:self.tableView];
    self.tableView.delegate = (id<UITableViewDelegate>)self;
    self.tableView.dataSource = (id<UITableViewDataSource>)self;
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"hahaha"];
    NSLog(@"0");
    
//    self.dataSet = [NSMutableArray arrayWithObjects:@"1", @"2", @"3", nil];
//    [self.tableView reloadData];
//    [self.tableView reloadData];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"A");
//        [self.dataSet removeObject:@"1"];
//        [self.tableView reloadData];
    });
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [self.dataSet removeObject:@"2"];
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [self.tableView reloadData];
//        });
//    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"B");
        [self _busyAction];
        [self _addBlock:^{
            NSLog(@"C");
        }];
    });
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSet.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *model = [self.dataSet objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"hahaha"];
    cell.textLabel.text = model;
    return cell;
}



#pragma mark - 多线程安全

- (void)_testMultiThread {
    __block int a = 0;
    dispatch_queue_t queue = dispatch_queue_create("Felix", DISPATCH_QUEUE_CONCURRENT);
    while (a < 5) {
        dispatch_async(queue, ^{
            a++;
        });
        dispatch_barrier_async(queue, ^{});
    }
    
    NSLog(@"此时的%d", a);
    sleep(1);
    NSLog(@"此时的%d", a);
}


#pragma mark - 下面代码有什么问题

- (void)_multiThread {
    static int staticVal = 0;
    if (staticVal ++ > 100) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self _multiThread];
        [self _test];
        self.myObj = [[GLObject alloc] init];
    });
}

- (void)_test {
    NSLog(@"%@", self.myObj);
}

#pragma mark - runloop & 线程 生命周期

- (void)test {
    NSLog(@"2");
}

- (void)_thread1 {
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        NSLog(@"1");
        [self performSelector:@selector(test) withObject:nil afterDelay:0];
        NSLog(@"3");
    });
}

- (void)_thread2 {
    NSThread *thread = [[NSThread alloc] initWithBlock:^{
        NSLog(@"1");
    }];
    [thread start];
    [self performSelector:@selector(test) onThread:thread withObject:nil waitUntilDone:YES];
}


#pragma mark - 线程生命周期

- (void)_thread3 {
    static int tag = 0;
    self.thread = [[NSThread alloc] initWithBlock:^{
        while (1) {
            tag ++;
            if (tag > 99999999) {
                NSLog(@"0");
                tag = 0;
            }
            if (self.threadBlock) {
                NSLog(@"0 exit");
                [NSThread exit];
//                NSLog(@"0 stop");
//                [NSThread sleepForTimeInterval:2];
//                NSLog(@"0 resume");
//                self.threadBlock = NO;
            }
        }
    }];
    [self.thread start];
}

- (void)_thread4 {
    static int tag = 0;
    self.thread2 = [[NSThread alloc] initWithBlock:^{
        while (1) {
            tag ++;
            if (tag > 99999999) {
                NSLog(@"1");
                tag = 0;
            }
            if (self.threadBlock2) {
                NSLog(@"1 stop");
                [NSThread sleepForTimeInterval:2];
                NSLog(@"1 resume");
                self.threadBlock2 = NO;
            }
        }
    }];
    [self.thread2 start];
}

/**
 线程生命周期：
 1、new
 实例化线程对象
 2、start    就绪 runnable
 向线程对象发送start消息，线程对象被加入可调度线程池，等待CPU调度
 3、CPU调度    运行 running
 CPU负责调度科调度线程池中的线程，进行运行。
 （线程完成任务之前：会在就绪 & 运行 2个状态之前来回切换，这是CPU负责的，程序员不能干预）
 4、休眠/等待同步锁     阻塞 blocked
 sleepForTimeInterval休眠指定时长、等待 @synchronized互斥锁
 5、exit或者cancel     死亡 dead
 正常死亡：线程执行完毕；非正常死亡：线程内部终止执行，调用了exit或者cancel方法
 cancel并未真正取消线程，只是给线程打了一个标识isCancelled
 */


#pragma mark - runloop & thread

- (void)_testRunloopAndThread
{
    static int tag = 0;
    self.thread = [[NSThread alloc] initWithBlock:^{
        [NSThread addAutoreleasePoolToCurrentRunloop];
        NSLog(@"thread.dic : %@\n", [NSThread currentThread].threadDictionary);
        
        while (1) {
            tag ++;
            if (tag > 99999999) {
                NSLog(@"0");
                tag = 0;
            }
            if (self.threadBlock) {
                NSLog(@"0 exit");
                [NSThread exit];
//                NSLog(@"0 stop");
//                [NSThread sleepForTimeInterval:2];
//                NSLog(@"0 resume");
//                self.threadBlock = NO;
            }
        }
    }];
    [self.thread start];
}


@end
