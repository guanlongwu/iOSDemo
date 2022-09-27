//
//  CrashReportFilter.m
//  YYTool
//
//  Created by wugl on 2022/8/13.
//

#import "CrashReportFilter.h"
#import "KSJSONCodecObjC.h"
#import "KSHTTPMultipartPostBody.h"
#import <Network/Network.h>

@implementation CrashReportFilter

+ (CrashReportFilter*)sink {
    return [[CrashReportFilter alloc]init] ;
}

- (CrashReportFilter*)defaultCrashReportFilterSet{
    return self;
}

- (void)filterReports:(NSArray *)reports
         onCompletion:(KSCrashReportFilterCompletion)onCompletion{
    NSError *error;
    for (id object in reports) {
        NSData *jsonData = [KSJSONCodec encode:object options:KSJSONEncodeOptionSorted error:&error];
        KSHTTPMultipartPostBody *body = [[KSHTTPMultipartPostBody alloc] init];
        [body appendData:jsonData name:@"formFile" contentType:@"application/json" filename:@"reports.json"];
//        [[Network share] uploadCrashByData:[body data] contengType:body.contentType completion:^(NSError * _Nullable error) {
//            kscrash_callCompletion(onCompletion, reports, error == nil, error);
//        }];
    }
}

@end
