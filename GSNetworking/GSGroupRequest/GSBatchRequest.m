//
//  BatchRequest.m
//
//  Copyright (c)  BRBR Co.ltd 

#import "GSBatchRequest.h"
#import "GSNetworkPrivate.h"
#import "GSBatchRequestAgent.h"
#import "GSRequest.h"

@interface GSBatchRequest() <GSRequestDelegate>

@property (nonatomic) NSInteger finishedCount;

@end

@implementation GSBatchRequest

- (instancetype)initWithRequestArray:(NSArray<GSRequest *> *)requestArray {
    self = [super init];
    if (self) {
        _requestArray = [requestArray copy];
        _finishedCount = 0;
        for (GSRequest * req in _requestArray) {
            if (![req isKindOfClass:[GSRequest class]]) {
                GSNLog(@"Error, request item must be GSRequest instance.");
                return nil;
            }
        }
    }
    return self;
}

- (void)start {
    if (_finishedCount > 0) {
        GSNLog(@"Error! Batch request has already started.");
        return;
    }
    _failedRequest = nil;
    [[GSBatchRequestAgent sharedAgent] addBatchRequest:self];
    [self toggleAccessoriesWillStartCallBack];
    for (GSRequest * req in _requestArray) {
        req.delegate = self;
        [req clearCompletionBlock];
        [req start];
    }
}

- (void)cancel {
    [self toggleAccessoriesWillStopCallBack];
    _delegate = nil;
    [self clearRequest];
    [self toggleAccessoriesDidStopCallBack];
    [[GSBatchRequestAgent sharedAgent] removeBatchRequest:self];
}

- (void)startWithSuccess:(void (^)(GSBatchRequest *batchRequest))success
                 failure:(void (^)(GSBatchRequest *batchRequest))failure {
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}

- (void)setCompletionBlockWithSuccess:(void (^)(GSBatchRequest *batchRequest))success
                              failure:(void (^)(GSBatchRequest *batchRequest))failure {
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
    
    // 同时清除 accessory
    self.requestAccessories = nil;
}

- (BOOL)isDataFromCache {
    BOOL result = YES;
    for (GSRequest *request in _requestArray) {
        if (!request.isDataFromCache) {
            result = NO;
        }
    }
    return result;
}


- (void)dealloc {
    [self clearRequest];
}

#pragma mark - Network Request Delegate

- (void)requestFinished:(GSRequest *)request {
    _finishedCount++;
    if (_finishedCount == _requestArray.count) {
        [self toggleAccessoriesWillStopCallBack];
        if ([_delegate respondsToSelector:@selector(batchRequestFinished:)]) {
            [_delegate batchRequestFinished:self];
        }
        if (_successCompletionBlock) {
            _successCompletionBlock(self);
        }
        [self clearCompletionBlock];
        [self toggleAccessoriesDidStopCallBack];
        [[GSBatchRequestAgent sharedAgent] removeBatchRequest:self];
    }
}

- (void)requestFailed:(GSRequest *)request {
    _failedRequest = request;
    [self toggleAccessoriesWillStopCallBack];
    // Stop
    for (GSRequest *req in _requestArray) {
        [req cancel];
    }
    // Callback
    if ([_delegate respondsToSelector:@selector(batchRequestFailed:)]) {
        [_delegate batchRequestFailed:self];
    }
    if (_failureCompletionBlock) {
        _failureCompletionBlock(self);
    }
    // Clear
    [self clearCompletionBlock];

    [self toggleAccessoriesDidStopCallBack];
    [[GSBatchRequestAgent sharedAgent] removeBatchRequest:self];
}

- (void)clearRequest {
    for (GSRequest * req in _requestArray) {
        [req cancel];
    }
    [self clearCompletionBlock];
}

#pragma mark - Request Accessoies

- (void)addAccessory:(id<GSRequestAccessory>)accessory {
    if (!accessory) return;
    if (!self.requestAccessories) {
        self.requestAccessories = [NSMutableArray array];
    }
    [self.requestAccessories addObject:accessory];
}

@end


@implementation GSBatchRequest (GSErrorMsg)

- (NSString *)errorMsg {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:2];
    for (GSRequest *request in self.requestArray) {
        NSString *msg = request.errorMsg;
        if (msg) [array addObject:msg];
    }
    
    return [array componentsJoinedByString:@"\n"];
}

@end
