//
//  ChainRequest.h
//
//  Copyright (c)  BRBR Co.ltd 

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class GSChainRequest;
@class GSRootRequest;
@protocol GSRequestAccessory;

///  The GSChainRequestDelegate protocol defines several optional methods you can use
///  to receive network-related messages. All the delegate methods will be called
///  on the main queue. Note the delegate methods will be called when all the requests
///  of chain request finishes.
@protocol GSChainRequestDelegate <NSObject>

@optional
///  Tell the delegate that the chain request has finished successfully.
///
///  @param chainRequest The corresponding chain request.
- (void)chainRequestFinished:(GSChainRequest *)chainRequest;

///  Tell the delegate that the chain request has failed.
///
///  @param chainRequest The corresponding chain request.
///  @param request      First failed request that causes the whole request to fail.
- (void)chainRequestFailed:(GSChainRequest *)chainRequest failedBaseRequest:(GSRootRequest *)request;

@end

typedef void (^GSChainCallback)(GSChainRequest *chainRequest, GSRootRequest *baseRequest);

///  BatchRequest can be used to chain several GSRequest so that one will only starts after another finishes.
///  Note that when used inside ChainRequest, a single GSRequest will have its own callback and delegate
///  cleared, in favor of the batch request callback.
@interface GSChainRequest : NSObject

///  All the requests are stored in this array.
- (NSArray<GSRootRequest *> *)requestArray;

///  The delegate object of the chain request. Default is nil.
@property (nonatomic, weak, nullable) id <GSChainRequestDelegate> delegate;

///  This can be used to add several accossories object. Note if you use `addAccessory` to add acceesory
///  this array will be automatically created. Default is nil.
@property (nonatomic, strong, nullable) NSMutableArray<id<GSRequestAccessory>> *requestAccessories;

///  Convenience method to add request accessory. See also `requestAccessories`.
- (void)addAccessory:(id<GSRequestAccessory>)accessory;

///  Start the chain request, adding first request in the chain to request queue.
- (void)start;

///  cancel the chain request. Remaining request in chain will be cancelled.
- (void)cancel;

///  Add request to request chain.
///
///  @param request  The request to be chained.
///  @param callback The finish callback
- (void)addRequest:(GSRootRequest *)request callback:(nullable GSChainCallback)callback;

@end

NS_ASSUME_NONNULL_END
