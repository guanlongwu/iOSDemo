//
// Copyright (c) 2008-present, Meitu, Inc.
// All rights reserved.
//
// This source code is licensed under the license found in the LICENSE file in
// the root directory of this source tree.
//
// Created on: 25/07/2017
// Created by: EuanC
//


#import "MTHNetworkRecorder.h"
#import "MTHNetworkCurlLogger.h"
#import "MTHNetworkStat.h"
#import "MTHNetworkTransaction.h"
#import "MTHawkeyeUtility.h"
#import "NSData+MTHawkeyeNetwork.h"

#import <MTHawkeye/MTHawkeyeLogMacros.h>


@interface MTHNetworkRecorder ()
@property (nonatomic, strong) NSMutableDictionary *networkTransactionsForRequestIdentifiers;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) NSHashTable<id<MTHNetworkRecorderDelegate>> *delegates;
@end

@implementation MTHNetworkRecorder

- (instancetype)init {
    (self = [super init]);
    if (self) {
        self.networkTransactionsForRequestIdentifiers = [NSMutableDictionary dictionary];
        self.delegates = [NSHashTable weakObjectsHashTable];

        // Serial queue used because we use mutable objects that are not thread safe
        self.queue = dispatch_queue_create("com.meitu.hawkeye.network.recorder", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

+ (instancetype)defaultRecorder {
    static MTHNetworkRecorder *defaultRecorder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultRecorder = [[[self class] alloc] init];
    });
    return defaultRecorder;
}

- (void)addDelegate:(id<MTHNetworkRecorderDelegate>)delegate {
    @synchronized(self.delegates) {
        [self.delegates addObject:delegate];
    }
}

- (void)removeDelegate:(id<MTHNetworkRecorderDelegate>)delegate {
    @synchronized(self.delegates) {
        [self.delegates removeObject:delegate];
    }
}

#pragma mark - Network Events

- (void)recordRequestWillBeSentWithRequestID:(NSString *)requestID
                                     request:(NSURLRequest *)request
                            redirectResponse:(NSURLResponse *)redirectResponse {
    for (NSString *host in self.hostBlacklist) {
        if ([request.URL.host hasSuffix:host]) {
            return;
        }
    }

    NSDate *startDate = [NSDate date];

    if (redirectResponse) {
        [self recordResponseReceivedWithRequestID:requestID response:redirectResponse];
    }

    NSURLRequest *copyRequest = [request copy];
    dispatch_async(self.queue, ^{
        MTHNetworkTransaction *transaction = self.networkTransactionsForRequestIdentifiers[requestID];
        if (transaction) {
            return;
        }
        static NSInteger index = 1;
        transaction = [[MTHNetworkTransaction alloc] init];
        transaction.requestID = requestID;
        transaction.request = copyRequest;
        transaction.startTime = startDate;
        transaction.requestIndex = index++;
        transaction.netQualityAtStart = [MTHNetworkStat shared].connQuality;
        [self.networkTransactionsForRequestIdentifiers setObject:transaction forKey:requestID];
        transaction.transactionState = MTHNetworkTransactionStateAwaitingResponse;

        [self cacheNewTransaction:transaction];
    });
}

- (void)recordRequestTaskAPIUsageWithRequestID:(NSString *)requestID
                                  taskAPIUsage:(MTHNetworkTaskAPIUsage *)taskAPIUsage
                     taskSessionConfigAPIUsage:(MTHNetworkTaskSessionConfigAPIUsage *)taskSessionConfigAPIUsage {
    dispatch_async(self.queue, ^{
        MTHNetworkTransaction *transaction = self.networkTransactionsForRequestIdentifiers[requestID];
        if (!transaction) {
#if MTHawkeyeNetworkDebugEnabled
            MTHLogWarn(@"record network transaction API Usage failed.");
#endif
            return;
        }
        transaction.isUsingURLSession = YES;
        transaction.sessionTaskAPIUsage = taskAPIUsage;
        transaction.sessionConfigAPIUsage = taskSessionConfigAPIUsage;

        // ???????????????????????????????????????????????????????????????????????????????????????
    });
}

- (void)recordResponseReceivedWithRequestID:(NSString *)requestID response:(NSURLResponse *)response {
    NSDate *responseDate = [NSDate date];
    NSURLResponse *copyResponse = [response copy];
    dispatch_async(self.queue, ^{
        MTHNetworkTransaction *transaction = self.networkTransactionsForRequestIdentifiers[requestID];
        if (!transaction) {
#if MTHawkeyeNetworkDebugEnabled
            MTHLogWarn(@"record network transaction response received failed.");
#endif
            return;
        }
        transaction.response = copyResponse;
        transaction.transactionState = MTHNetworkTransactionStateReceivingData;
        transaction.latency = -[transaction.startTime timeIntervalSinceDate:responseDate];

        [self cacheTransactionAsUpdate:transaction];
    });
}

- (void)recordDataReceivedWithRequestID:(NSString *)requestID dataLength:(int64_t)dataLength {
    dispatch_async(self.queue, ^{
        MTHNetworkTransaction *transaction = self.networkTransactionsForRequestIdentifiers[requestID];
        if (!transaction) {
#if MTHawkeyeNetworkDebugEnabled
            MTHLogWarn(@"record network transaction data received failed.");
#endif
            return;
        }
        transaction.receivedDataLength += dataLength;

        [self cacheTransactionAsUpdate:transaction];
    });
}

- (void)recordLoadingFinishedWithRequestID:(NSString *)requestID responseBody:(NSData *)responseBody {
    NSDate *finishedDate = [NSDate date];
    NSData *copyResponseBody = [responseBody copy];
    dispatch_async(self.queue, ^{
        MTHNetworkTransaction *transaction = self.networkTransactionsForRequestIdentifiers[requestID];
        if (!transaction) {
#if MTHawkeyeNetworkDebugEnabled
            MTHLogWarn(@"record network transaction loading finished failed, transaction released: %@.", requestID);
#endif
            return;
        }

        transaction.duration = -[transaction.startTime timeIntervalSinceDate:finishedDate];
        transaction.netQualityAtEnd = [MTHNetworkStat shared].connQuality;

        if (transaction.responseContentType != MTHNetworkHTTPContentTypeOther && [copyResponseBody length] > 0) {
            transaction.responseDataMD5 = [copyResponseBody MTHNetwork_MD5HexDigest];
            transaction.responseBody = copyResponseBody;
        } else {
            // ???????????? response ?????????????????????????????????????????????
            transaction.responseBody = copyResponseBody;
            [transaction requestLength];
            transaction.responseBody = nil;
        }

        transaction.transactionState = MTHNetworkTransactionStateFinished;

        [self cacheTransactionAsUpdate:transaction];
        [self.networkTransactionsForRequestIdentifiers removeObjectForKey:requestID];
    });
}

- (void)recordLoadingFailedWithRequestID:(NSString *)requestID error:(NSError *)error {
    dispatch_async(self.queue, ^{
        MTHNetworkTransaction *transaction = self.networkTransactionsForRequestIdentifiers[requestID];
        if (!transaction) {
#if MTHawkeyeNetworkDebugEnabled
            MTHLogWarn(@"record network transaction loading failure failed.");
#endif
            return;
        }
        transaction.duration = -[transaction.startTime timeIntervalSinceNow];
        transaction.error = error;
        transaction.netQualityAtEnd = [MTHNetworkStat shared].connQuality;
        transaction.transactionState = MTHNetworkTransactionStateFailed;

        [self cacheTransactionAsUpdate:transaction];
        [self.networkTransactionsForRequestIdentifiers removeObjectForKey:requestID];
    });
}

- (void)recordMetricsWithRequestID:(NSString *)requestID metrics:(NSURLSessionTaskMetrics *)metrics {
    dispatch_async(self.queue, ^{
        MTHNetworkTransaction *transaction = self.networkTransactionsForRequestIdentifiers[requestID];
        if (!transaction) {
#if MTHawkeyeNetworkDebugEnabled
            MTHLogWarn(@"record network transaction metrics failed.");
#endif
            return;
        }

        transaction.taskMetrics = [MTHURLSessionTaskMetrics metricsFromSystemMetrics:metrics];
        [self cacheTransactionAsUpdate:transaction];
    });
}

- (void)recordMechanism:(NSString *)mechanism forRequestID:(NSString *)requestID {
    dispatch_async(self.queue, ^{
        MTHNetworkTransaction *transaction = self.networkTransactionsForRequestIdentifiers[requestID];
        if (!transaction) {
#if MTHawkeyeNetworkDebugEnabled
            MTHLogWarn(@"record network transaction mechanism failed.");
#endif
            return;
        }
        transaction.requestMechanism = mechanism;

        [self cacheTransactionAsUpdate:transaction];
    });
}

#pragma mark - Cache

- (void)cacheNewTransaction:(MTHNetworkTransaction *)transaction {
    @synchronized(self.delegates) {
        for (id<MTHNetworkRecorderDelegate> delegate in self.delegates) {
            if ([delegate respondsToSelector:@selector(recorderWantCacheNewTransaction:)])
                [delegate recorderWantCacheNewTransaction:transaction];
        }
    }
}

- (void)cacheTransactionAsUpdate:(MTHNetworkTransaction *)transaction {
    // ??????????????? state, ????????????????????????transaction.state ???????????????
    MTHNetworkTransactionState state = transaction.transactionState;
    @synchronized(self.delegates) {
        for (id<MTHNetworkRecorderDelegate> delegate in self.delegates) {
            if ([delegate respondsToSelector:@selector(recorderWantCacheTransactionAsUpdated:currentState:)])
                [delegate recorderWantCacheTransactionAsUpdated:transaction currentState:state];
        }
    }
}

@end
