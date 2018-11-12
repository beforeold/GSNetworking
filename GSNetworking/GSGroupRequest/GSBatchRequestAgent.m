//
//  BatchRequestAgent.m
//
//  Copyright (c)  BRBR Co.ltd 

#import "GSBatchRequestAgent.h"
#import "GSBatchRequest.h"

@interface GSBatchRequestAgent()

@property (strong, nonatomic) NSMutableArray<GSBatchRequest *> *requestArray;

@end

@implementation GSBatchRequestAgent

+ (GSBatchRequestAgent *)sharedAgent {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _requestArray = [NSMutableArray array];
    }
    return self;
}

- (void)addBatchRequest:(GSBatchRequest *)request {
    @synchronized(self) {
        if (request) [_requestArray addObject:request];
    }
}

- (void)removeBatchRequest:(GSBatchRequest *)request {
    @synchronized(self) {
        [_requestArray removeObject:request];
    }
}

@end
