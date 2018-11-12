//
//  GSBatchRequest.h
//
//  Copyright (c)  BRBR Co.ltd 

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class GSRequest;
@class GSBatchRequest;
@protocol GSRequestAccessory;

///  The GSBatchRequestDelegate protocol defines several optional methods you can use
///  to receive network-related messages. All the delegate methods will be called
///  on the main queue. Note the delegate methods will be called when all the requests
///  of batch request finishes.
@protocol GSBatchRequestDelegate <NSObject>

@optional
///  Tell the delegate that the batch request has finished successfully/
///
///  @param batchRequest The corresponding batch request.
- (void)batchRequestFinished:(GSBatchRequest *)batchRequest;

///  Tell the delegate that the batch request has failed.
///
///  @param batchRequest The corresponding batch request.
- (void)batchRequestFailed:(GSBatchRequest *)batchRequest;

@end

///  BatchRequest can be used to batch several GSRequest. Note that when used inside BatchRequest, a single
///  GSRequest will have its own callback and delegate cleared, in favor of the batch request callback.
@interface GSBatchRequest : NSObject

///  All the requests are stored in this array.
@property (nonatomic, strong, readonly) NSArray<GSRequest *> *requestArray;

///  The delegate object of the batch request. Default is nil.
@property (nonatomic, weak, nullable) id <GSBatchRequestDelegate> delegate;

///  The success callback. Note this will be called only if all the requests are finished.
///  This block will be called on the main queue.
@property (nonatomic, copy, nullable) void (^successCompletionBlock)(GSBatchRequest *);

///  The failure callback. Note this will be called if one of the requests fails.
///  This block will be called on the main queue.
@property (nonatomic, copy, nullable) void (^failureCompletionBlock)(GSBatchRequest *);

///  Tag can be used to identify batch request. Default value is 0.
@property (nonatomic) NSInteger tag;


///  The first request that failed (and causing the batch request to fail).
@property (nonatomic, strong, readonly, nullable) GSRequest *failedRequest;

///  Creates a `BatchRequest` with a bunch of requests.
///
///  @param requestArray requests useds to create batch request.
///
- (instancetype)initWithRequestArray:(NSArray<GSRequest *> *)requestArray;

///  Set completion callbacks
- (void)setCompletionBlockWithSuccess:(nullable void (^)(GSBatchRequest *batchRequest))success
                              failure:(nullable void (^)(GSBatchRequest *batchRequest))failure;

///  Nil out both success and failure callback blocks.
- (void)clearCompletionBlock;


///  This can be used to add several accossories object. Note if you use `addAccessory` to add acceesory
///  this array will be automatically created. Default is nil.
@property (nonatomic, strong, nullable) NSMutableArray<id<GSRequestAccessory>> *requestAccessories;

///  Convenience method to add request accessory. See also `requestAccessories`.
- (void)addAccessory:(id<GSRequestAccessory>)accessory;

///  Append all the requests to queue.
- (void)start;

///  cancel all the requests of the batch request.
- (void)cancel;

///  Convenience method to start the batch request with block callbacks.
- (void)startWithSuccess:(nullable void (^)(GSBatchRequest *batchRequest))success
                 failure:(nullable void (^)(GSBatchRequest *batchRequest))failure;

///  Whether all response data is from local cache.
- (BOOL)isDataFromCache;

@end

@interface GSBatchRequest (GSErrorMsg)

/// 获取 batch 请求的综合错误信息进行拼接
@property (nonatomic, readonly, nullable) NSString *errorMsg;

@end

NS_ASSUME_NONNULL_END


