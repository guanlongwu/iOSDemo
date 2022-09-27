//
//  KvoAction.m
//  YYTool
//
//  Created by wugl on 2022/7/14.
//

#import "KvoAction.h"
#import "GLObject.h"
#import "GLView.h"

@interface KvoAction ()
@property (nonatomic, strong) GLObject *myObj;
@property (nonatomic, strong) GLView *myView;
@end

@implementation KvoAction

- (void)dealloc
{
    [_myView removeFromSuperview];
}

- (void)doWork
{
//    [self _testSafeKVO];
    
    [self _ifRunKVO];
}

#pragma mark - safe KVO

- (void)_testSafeKVO
{
    self.myView = [[GLView alloc] initWithFrame:CGRectMake(50, 300, 300, 300)];
    self.myView.backgroundColor = [UIColor redColor];
    [self.vc.view addSubview:self.myView];
    
    self.myObj = [GLObject new];
    self.myView.obj = self.myObj;
    self.myObj.name = @"wugl";
}

- (void)_postObserverForKVO
{
    [self.myView removeFromSuperview];
    self.myView = nil;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSLog(@"myObj.name is change start");
        self.myObj.name = @"wyl";
        NSLog(@"myObj.name is change end");
    });
}

#pragma mark - 是否会执行kvo

//- (void)_ifRunKVO {
//    [self addObserver:self forKeyPath:@"myObj" options:NSKeyValueObservingOptionNew context:nil];
//    self.myObj = [[GLObject alloc] init];
//}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
//    id oldName = [change objectForKey:NSKeyValueChangeOldKey];
//    NSLog(@"oldName----------%@",oldName);
//    id newName = [change objectForKey:NSKeyValueChangeNewKey];
//    NSLog(@"newName-----------%@",newName);
//    //当界面要消失的时候,移除kvo
////    [object removeObserver:self forKeyPath:@"name"];
//}

- (void)setMyObj:(GLObject *)myObj {
    if (_myObj != myObj) {
        _myObj = myObj;
    }
}

- (void)_ifRunKVO {
    self.myObj = [[GLObject alloc] init];
    self.myObj.name = @"1111";
    [self addObserver:self forKeyPath:@"myObj" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    self.myObj = [[GLObject alloc] init];
    self.myObj.name = @"2222";
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    id oldName = [change objectForKey:NSKeyValueChangeOldKey];
    NSLog(@"oldName----------%@",oldName);
    id newName = [change objectForKey:NSKeyValueChangeNewKey];
    NSLog(@"newName-----------%@",newName);
}


@end
