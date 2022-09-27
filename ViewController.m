//
//  ViewController.m
//  YYTool
//
//  Created by wugl on 2022/5/30.
//

#import "ViewController.h"
#import "GLObject.h"
#import "GLView.h"
#import "NSThread+YYAdd.h"
#import "NSObject+SafeKVO.h"
#import "NSObject+WeakProperty.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "GLSubObj.h"
#import "GLTool.h"
#import "GLString.h"
#import "NSObject+CrashGuard.h"
//#import "Stinger.h"

#import "RunLoopAction.h"
#import "KvoAction.h"
#import "AutoreleasepoolAction.h"
#import "DeallocOrderAction.h"
#import "MsgForwardAction.h"
#import "CALayerAction.h"
#import "ISA_ClassAction.h"
#import "LeiCuInheritAction.h"
#import "CTMediatorAction.h"
#import "FishhookAction.h"
#import "AspectsAction.h"
#import "LibffiAction.h"
#import "YYKitAction.h"
#import "GCDAction.h"
#import "MultiThreadAction.h"
#import "KSCrashAction.h"
#import "HookObjcMsgSendAction.h"

// interview题：https://xie.infoq.cn/article/b7524e3595b98a60d733d2cef


typedef void(^GLActionBlock)(void);

@interface GLActionModel : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) GLActionBlock block;

+ (id)modelWithTitle:(NSString *)title block:(GLActionBlock)block;

@end

@implementation GLActionModel

+ (id)modelWithTitle:(NSString *)title block:(GLActionBlock)block;
{
    GLActionModel *model = [GLActionModel new];
    model.block = block;
    model.title = title;
    return model;
}

@end


@interface ViewController ()
@property (nonatomic, strong) UITableView *mTableView;
@property (nonatomic, strong) NSArray <GLActionModel *>*datas;
@property (nonatomic, strong) id action;


@property (nonatomic, strong) GLObject *myObj;
@property (nonatomic, strong) GLView *myView;

@property (nonatomic, weak) GLObject *weakObj;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, weak) NSString *reference;
@property (nonatomic, strong) NSMutableArray *lockArr;
@property (nonatomic, strong) NSMutableArray *mList;

@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@property (atomic, strong) NSURLSession *session;
@property (atomic, strong) NSURLSessionDataTask *task;

@property (nonatomic, strong) GLObject *obj;
@end

@implementation ViewController


#pragma mark - 事件列表

- (NSArray <GLActionModel *>*)datas
{
    if (!_datas) {
        NSArray *list =
        @[
            [GLActionModel modelWithTitle:@"runloop" block:^{
                RunLoopAction *action = [RunLoopAction new];
                action.vc = self;
                [action doWork];
                self.action = action;
            }],
            
            [GLActionModel modelWithTitle:@"kvo" block:^{
                KvoAction *action = [KvoAction new];
                action.vc = self;
                [action doWork];
                self.action = action;
            }],
            
            [GLActionModel modelWithTitle:@"autoreleasepool" block:^{
                AutoreleasepoolAction *action = [AutoreleasepoolAction new];
                [action doWork];
                self.action = action;
            }],
            
            [GLActionModel modelWithTitle:@"deallocOrder" block:^{
                DeallocOrderAction *action = [DeallocOrderAction new];
                [action doWork];
                self.action = action;
            }],
            
            [GLActionModel modelWithTitle:@"MsgForward" block:^{
                MsgForwardAction *action = [MsgForwardAction new];
                [action doWork];
                self.action = action;
            }],
            
            [GLActionModel modelWithTitle:@"CALayer" block:^{
                CALayerAction *action = [CALayerAction new];
                action.vc = self;
                [action doWork];
                self.action = action;
            }],
            
            [GLActionModel modelWithTitle:@"ISA_Class" block:^{
                ISA_ClassAction *action = [ISA_ClassAction new];
                [action doWork];
                self.action = action;
            }],
            
            [GLActionModel modelWithTitle:@"LeiCuInherit" block:^{
                LeiCuInheritAction *action = [LeiCuInheritAction new];
                [action doWork];
                self.action = action;
            }],
            
            [GLActionModel modelWithTitle:@"LeiCuInherit" block:^{
                CTMediatorAction *action = [CTMediatorAction new];
                [action doWork];
                self.action = action;
            }],
            
            [GLActionModel modelWithTitle:@"Fishhook" block:^{
                FishhookAction *action = [FishhookAction new];
                [action doWork];
                self.action = action;
            }],
            
            [GLActionModel modelWithTitle:@"Aspects" block:^{
                AspectsAction *action = [AspectsAction new];
                [action doWork];
                self.action = action;
            }],
            
            [GLActionModel modelWithTitle:@"Libffi" block:^{
                LibffiAction *action = [LibffiAction new];
                [action doWork];
                self.action = action;
            }],
            
            [GLActionModel modelWithTitle:@"YYKit" block:^{
                YYKitAction *action = [YYKitAction new];
                [action doWork];
                self.action = action;
            }],
            
            [GLActionModel modelWithTitle:@"GCD" block:^{
                GCDAction *action = [GCDAction new];
                [action doWork];
                self.action = action;
            }],
            
            [GLActionModel modelWithTitle:@"MultiThread" block:^{
                MultiThreadAction *action = [MultiThreadAction new];
                [action doWork];
                self.action = action;
            }],
            
            [GLActionModel modelWithTitle:@"KSCrash" block:^{
                KSCrashAction *action = [KSCrashAction new];
                [action doWork];
                self.action = action;
            }],
            
            [GLActionModel modelWithTitle:@"HookObjcMsgSend" block:^{
                HookObjcMsgSendAction *action = [HookObjcMsgSendAction new];
                [action doWork];
                self.action = action;
            }],
        ];
        _datas = list;
    }
    return _datas;
}


#pragma mark - UI

- (void)setupUI
{
    self.mTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 50, self.view.frame.size.width, self.view.frame.size.height - 50) style:UITableViewStylePlain];
    [self.view addSubview:self.mTableView];
    self.mTableView.delegate = (id<UITableViewDelegate>)self;
    self.mTableView.dataSource = (id<UITableViewDataSource>)self;
    [self.mTableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"hahaha"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GLActionModel *model = [self.datas objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"hahaha"];
    cell.textLabel.text = model.title;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GLActionModel *model = [self.datas objectAtIndex:indexPath.row];
    GLActionBlock block = model.block;
    if (block) {
        block();
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Demo";
    [self setupUI];
    
//    [self obj];
    self.obj.name = @"wugl";
    
//    [self addRunLoopObserver];
//    self.blocks = [NSMutableArray array];
//    [self _testSafeKVO];
    
    
    
//    self.myView = [[GLView alloc] initWithFrame:CGRectMake(0, 0, 300, 600)];
//    self.myView.backgroundColor = [UIColor redColor];
//    [self.view addSubview:self.myView];
    
//    [self _deallocOrder];
//    [self _ifRunKVO];
//    [self _multiThread];
//    [self _setTable];
//    [self _testBlock];
//    [self _testMultiThread];
    
//    [self _thread3];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self _thread4];
//    });
    
//    NSString *str = [NSString stringWithFormat:@"sunnyxx"];
//    self.reference = str;
//    NSLog(@" %s -- value -- :%@", __func__, self.reference); // Console: sunnyxx
//    NSLog(@" %s -- pointer -- :%p", __func__, self.reference); // Console: sunnyxx
//
//    GLObject *obj = [[GLObject alloc] init];
//    self.weakObj = obj;
//    NSLog(@" %s -- value -- :%@", __func__, self.weakObj); // Console: sunnyxx
//    NSLog(@" %s -- pointer -- :%p", __func__, self.weakObj); // Console: sunnyxx
    
    
    // 探究objc_storeStrong底层实现（strong类型修饰符）
    /*
    GLObject *obj = [[GLObject alloc] init];
    obj.name = @"obj";
    self.strongObj = obj;
    NSLog(@"-- strong obj : %p", self.strongObj);
    GLObject *obj1 = [[GLObject alloc] init];
    obj1.name = @"obj1";
    self.strongObj = obj1;
    NSLog(@"-- strong obj : %p", self.strongObj);
    
    NSLog(@"-- obj : %p", obj);
    */
    
//    [self addBtn];
//
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(testNotify) name:@"NotificationName" object:nil];

    
}

- (GLObject *)obj
{
    if (!_obj) {
        _obj = [GLObject new];
//        __weak typeof(self) weakself = self;
//        self.obj.block = ^(NSString * _Nonnull name) {
//            __strong typeof(weakself) strongself = weakself;
//            NSLog(@"%@", name);
//        };
//        [self.obj doWork];
    }
    return _obj;
}

- (void)addBtn
{
    self.view.backgroundColor = [UIColor whiteColor];
    UILabel *titleL = [[UILabel alloc] initWithFrame:CGRectMake(50, 100, 300, 60)];
    titleL.backgroundColor = [UIColor greenColor];
    titleL.textColor = [UIColor redColor];
    titleL.text = @"i am a handsome by";
    titleL.font = [UIFont systemFontOfSize:24];
    [self.view addSubview:titleL];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    NSLog(@" %s --- :%@", __func__, self.weakObj); // Console: sunnyxx
//    NSLog(@" %s --- :%@", __func__, self.reference); // Console: sunnyxx
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    NSLog(@" %s --- :%@", __func__, self.reference); // Console: sunnyxx
}


#pragma mark - block知识点

- (void)_testBlock {
    __block int a = 0;
    while (a < 5) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            a++;
        });
    }
    NSLog(@"--- %d ---", a);
}


#pragma mark - sendEvent、hitTest view

- (void)_testEvent
{
    GLView *view1 = [[GLView alloc] initWithFrame:CGRectMake(50, 200, 300, 300)];
    view1.backgroundColor = [UIColor redColor];
    [self.view addSubview:view1];
//    GLView *view2 = [[GLView alloc] initWithFrame:CGRectMake(30, 30, 80, 80)];
//    view2.backgroundColor = [UIColor blueColor];
//    [view1 addSubview:view2];
}


#pragma mark - 锁

- (void)_testSynchronizedLock
{
    self.lockArr = [NSMutableArray array];
    
    @synchronized (self.lockArr) {
        [self.lockArr addObjectsFromArray:@[@1, @2, @3]];
        
        [self.lockArr enumerateObjectsUsingBlock:^(NSNumber  * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.intValue == 2) {
                [self _testSynchronizedLock2];
            }
        }];
//        [self _testSynchronizedLock2];
    }
    
    NSLog(@"lockArr : %@", self.lockArr);
}

- (void)_testSynchronizedLock2
{
    @synchronized (self.lockArr) {
        [self.lockArr removeLastObject];
    }
}


#pragma mark - weak 属性 测试

- (void)_testWeakCase {
    // 如果关联对象也支持weak这种特性就好了，关联的对象释放了，自动置空，宿主对象再次获取拿到的是个nil
    static char kTestWeakKey;
    {
        {
            UILabel *associatedLabel = [UILabel new];
            objc_setWeakAssociatedObject(self, &kTestWeakKey, associatedLabel);
//            objc_setAssociatedObject(self, &kTestWeakKey, associatedLabel, OBJC_ASSOCIATION_ASSIGN);
            //objc_setAssociatedObject(self, &kTestWeakKey, nil, OBJC_ASSOCIATION_ASSIGN);
        }
        UILabel *label = objc_getAssociatedObject(self, &kTestWeakKey);
        NSLog(@"label = %@", label); // 输出结果：null
    }
}


#pragma mark - block

// 创建一个全局静态的block类（单例）
static Class _BlockClass() {

    static dispatch_once_t onceToken;
    static Class blockClass;
    dispatch_once(&onceToken, ^{
        void (^testBlock)(void) = [^{} copy];
        blockClass = [testBlock class];

        while(class_getSuperclass(blockClass) && class_getSuperclass(blockClass) != [NSObject class]) {
            blockClass = class_getSuperclass(blockClass);
            NSLog(@"-- block class  : %@\n", NSStringFromClass(blockClass));
        }
        
        Class metaCls = objc_getMetaClass(class_getName(blockClass));
        while (metaCls) {
            metaCls = class_getSuperclass(metaCls);
            NSLog(@"==== meta class :  %@\n", metaCls);
        }

    });

    return blockClass;

}



#pragma mark - pb model enum

- (void)_testPBModelEnum
{
    GLObject *obj = [GLObject new];
    obj.type = 5;
    NSLog(@"wugl -- type : %d", obj.type);  // 5
    
    GLObject *copy = [obj copy];
    NSLog(@"copy -- type : %d", copy.type);
}

#pragma mark - 实现 多继承 ： 消息转发 / protocol / NSPorxy

- (void)_multiInherit
{
    
}


#pragma mark - multi thread safe

/// https://blog.csdn.net/u011619283/article/details/53135502
/// enumerateObjectsUsingBlock 遍历中删除元素，不会crash
/// for in 遍历中删除元素，crash
/// for 遍历删除元素，不会crash
- (void)_removeInForInAPIWillCrash
{
    
    self.mList = [NSMutableArray array];
    for (int i=0; i<9999999; i++) {
        [self.mList addObject:@(i)];
    }
    
    NSLog(@"wugl -- 0");
    NSArray <NSNumber *>*copyList = [self.mList copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"wugl -- 1 %@", [NSThread currentThread]);
//        [NSThread sleepForTimeInterval:1];
//        static int value = 0;
//        for (int i=0; i<999999; i++) {
//            value += i;
//        }
        
//        self.semaphore = dispatch_semaphore_create(0);
//        for (NSNumber *obj in self.mList) {
//            if (obj.longLongValue == 999) {
////                NSLog(@"wugl -- list.count = %lu", (unsigned long)self.mList.count);
//                sleep(3.1);
//            }
//            if (obj.longLongValue == 99999) {
//                NSLog(@"wugl -- 1 list.count = %lu", (unsigned long)self.mList.count);
////                [self.mList removeObject:@(1001)];
//            }
//            if (obj.longLongValue == 999999) {
//                NSLog(@"wugl -- 2  ");
//            }
//            NSLog(@"wugl for in -- %lld", obj.longLongValue);
//        }
        
//        for (int i=0; i<self.mList.count; i++) {
//            NSNumber *obj = self.mList[i];
//            if (obj.longLongValue == 999) {
//                NSLog(@"wugl -- list.count = %lu", (unsigned long)self.mList.count);
//                sleep(3.1);
//            }
//            if (obj.longLongValue == 1000) {
//                NSLog(@"wugl -- list.count = %lu", (unsigned long)self.mList.count);
//                [self.mList removeObject:@(1001)];
//            }
//        }
        
        [self.mList enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.longLongValue == 999) {
                NSLog(@"wugl -- list.count = %lu", (unsigned long)self.mList.count);
                sleep(3.1);
            }
            if (obj.longLongValue == 1000000) {
                NSLog(@"wugl -- list.count = %lu", (unsigned long)self.mList.count);
                [self.mList removeObject:@(1001)];
//                dispatch_semaphore_signal(self.semaphore);
            }
        }];
//        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
//        NSLog(@"wugl -- 2 %@", [NSThread currentThread]);
    });
    
    NSLog(@"wugl -- 3 %@", [NSThread currentThread]);
//    [self.mList removeObject:@(99999)];
//    self.mList = [NSMutableArray arrayWithObjects:@(1), @(2), @(999), nil];
    NSLog(@"wugl -- 4 %@", [NSThread currentThread]);
}



#pragma mark - init/dealloc中不要调用setter方法

- (void)_testSetterInInit
{
    GLSubObj *subObj = [[GLSubObj alloc] init];
    [subObj run];
}

- (void)_testSetterInDealloc
{
    GLSubObj *subObj = [[GLSubObj alloc] init];
    
}



#pragma mark - cookie

- (void)_testCookie
{
    NSHTTPCookieStorage *cookieStroge = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    [cookieStroge.cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"cache - cookie:%@", obj);
    }];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:(id<NSURLSessionDelegate>)self delegateQueue:queue];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.jianshu.com/"]];
    self.task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if ([response isKindOfClass:NSHTTPURLResponse.class]) {
            NSHTTPURLResponse *httpRsp = (NSHTTPURLResponse *)response;
            NSDictionary *headerFields = httpRsp.allHeaderFields;
            NSLog(@"request - headerFields:%@", headerFields);
        }
    }];
    
}




#pragma mark - test code

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    [self _thread1];    /// performSelector after 是基于 timer 定制器,定时器又是基于 runloop 实现的;任务2在子线程中,子线程默认 runloop 是不开启的,所以不执行2
//    [self _thread2];  /// start 执行完,线程就销毁了. 输出1，然后crash
    
//    self.threadBlock = YES;
//    self.threadBlock2 = !self.threadBlock;
//    if (NO == self.thread2.isCancelled) {
//        NSLog(@"thread2 cancel");
//        [self.thread2 cancel];
//    }
//    else {
//        NSLog(@"thread resume");
////        [self.thread2 ];
//    }
    
//    [self _setTable];
    
//    [self _testLayer];
//    [self _runCADisplayLink];
    
//    [self _testRunloopAndThread];
    
//    [self _testEvent];
    
//    [self _testAutoreleasepool];
    
//    NSLog(@" %s --- :%@", __func__, self.reference); // Console: sunnyxx
    
//    [self _testSynchronizedLock];
    
//    [self _postObserverForKVO];
    
//    [self _testWeakCase];
    
//    [self.myView removeFromSuperview];
//    self.myView = nil;
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        NSLog(@"wugl - post notify");
//        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyName object:nil];
//    });
    
//    dispatch_queue_t queue = dispatch_queue_create("test.queue", DISPATCH_QUEUE_SERIAL);
//    dispatch_async(queue, ^{    // 异步执行 + 串行队列
//        NSLog(@"--current thread: %@", [NSThread currentThread]);
//        NSLog(@"Begin post notification");
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"NotificationName" object:nil];
//        NSLog(@"End");
//    });
    
//        Class cls = _BlockClass();
//        NSLog(@"block class : %@", NSStringFromClass(cls));
        
//    [self _objcMsgSend];
    
//    [self _testCrashGuard];
    
//    [self _testClass];
    
//    [self _testPBModelEnum];
    
//    ATH_NSBlock_hookOnces();
    
//    [self _testMethodSwizzle];
    
//    [self _testClassAPI];
    
//    [self _removeInForInAPIWillCrash];
    
//    [self _testLeiCu];
    
//    [self _testISA];
    
//    [self _testSetterInInit];
//    [self _testSetterInDealloc];
    
//    [self _testCTMediator];
    
//    [self _testFishhook];
    
    
    
    [self _testCookie];
    
}

- (void)testNotify {
    NSLog(@"--current thread: %@", [NSThread currentThread]);
    NSLog(@"Handle notification and sleep 3s");
    sleep(3);
}


@end



