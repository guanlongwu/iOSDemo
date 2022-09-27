//
//  CTMediatorAction.m
//  YYTool
//
//  Created by wugl on 2022/7/14.
//

#import "CTMediatorAction.h"
#import "CTViewController.h"

@implementation CTMediatorAction

- (void)doWork
{
    [self _testCTMediator];
}


#pragma mark - 跳转CTMediator

- (void)_testCTMediator
{
    CTViewController *vc = [CTViewController new];
    [self.vc.view addSubview:vc.view];
    [self.vc addChildViewController:vc];
}

@end
