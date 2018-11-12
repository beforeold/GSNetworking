//
//  ChainRequestAgent.m
//
//  Copyright (c)  BRBR Co.ltd 

#import "GSChainRequestAgent.h"
#import "GSChainRequest.h"

@interface GSChainRequestAgent()

@property (strong, nonatomic) NSMutableArray<GSChainRequest *> *requestArray;

@end

@implementation GSChainRequestAgent

+ (GSChainRequestAgent *)sharedAgent {
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

- (void)addChainRequest:(GSChainRequest *)request {
    @synchronized(self) {
        if(request) [_requestArray addObject:request];
    }
}

- (void)removeChainRequest:(GSChainRequest *)request {
    @synchronized(self) {
        [_requestArray removeObject:request];
    }
}

@end
