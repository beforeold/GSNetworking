//
//  BatchRequestAgent.h
//
//  Copyright (c)  BRBR Co.ltd 

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class GSBatchRequest;

///  BatchRequestAgent handles batch request management. It keeps track of all
///  the batch requests.
@interface GSBatchRequestAgent : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

///  Get the shared batch request agent.
+ (GSBatchRequestAgent *)sharedAgent;

///  Add a batch request.
- (void)addBatchRequest:(GSBatchRequest *)request;

///  Remove a previously added batch request.
- (void)removeBatchRequest:(GSBatchRequest *)request;

@end

NS_ASSUME_NONNULL_END
