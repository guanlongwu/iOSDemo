//
//  CrashInstallation.m
//  YYTool
//
//  Created by wugl on 2022/8/13.
//

#import "CrashInstallation.h"
#import "KSCrashInstallation+Private.h"

@implementation CrashInstallation

#pragma 单列方法

+(CrashInstallation *)share {
    static CrashInstallation *shareManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareManager = [[CrashInstallation alloc] init];
    });
    return shareManager;
}

- (id)init {
    self = [super initWithRequiredProperties:@[]];
    return self;
}

- (id<KSCrashReportFilter>)sink {
    return [[CrashReportFilter alloc]init];
}

@end
