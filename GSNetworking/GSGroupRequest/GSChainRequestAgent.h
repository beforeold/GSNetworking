//
//  ChainRequestAgent.h
//
//  Copyright (c)  BRBR Co.ltd 

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class GSChainRequest;

///  ChainRequestAgent handles chain request management. It keeps track of all
///  the chain requests.
@interface GSChainRequestAgent : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

///  Get the shared chain request agent.
+ (GSChainRequestAgent *)sharedAgent;

///  Add a chain request.
- (void)addChainRequest:(GSChainRequest *)request;

///  Remove a previously added chain request.
- (void)removeChainRequest:(GSChainRequest *)request;

@end

NS_ASSUME_NONNULL_END
