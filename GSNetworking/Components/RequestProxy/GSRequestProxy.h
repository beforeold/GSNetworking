//
//  GSNetworkAgent.h
//
//  Copyright (c)  BRBR Co.ltd 

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class GSRootRequest;

///  RequestProxy is the underlying class that handles actual request generation,
///  serialization and response handling.
@interface GSRequestProxy : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

///  Get the shared proxy.
+ (GSRequestProxy *)sharedProxy;

///  Add request to session and start it.
- (void)addRequest:(GSRootRequest *)request;

///  Cancel a request that was previously added.
- (void)cancelRequest:(GSRootRequest *)request;

///  Cancel all requests that were previously added.
- (void)cancelAllRequests;

@end

NS_ASSUME_NONNULL_END
