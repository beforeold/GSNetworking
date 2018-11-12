//
//  NetworkConfig.h
//
//  Copyright (c)  BRBR Co.ltd 

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class GSRootRequest;
@class AFSecurityPolicy;

///  GSURLFilterProtocol can be used to append common parameters to requests before sending them.
@protocol GSURLFilterProtocol <NSObject>
///  Preprocess request URL before actually sending them.
///
///  @param originUrl request's origin URL, which is returned by `requestURL`
///  @param request   request itself
///
///  @return A new url which will be used as a new `requestURL`
- (NSString *)filterUrl:(NSString *)originUrl withRequest:(GSRootRequest *)request;
@end

///  GSCacheDirPathFilterProtocol can be used to append common path components when caching response results
@protocol GSCacheDirPathFilterProtocol <NSObject>
///  Preprocess cache path before actually saving them.
///
///  @param originPath original base cache path, which is generated in `GSRequest` class.
///  @param request    request itself
///
///  @return A new path which will be used as base path when caching.
- (NSString *)filterCacheDirPath:(NSString *)originPath withRequest:(GSRootRequest *)request;
@end

///  NetworkConfig stored global network-related configurations, which will be used in `RequestAgent`
///  to form and filter requests, as well as caching response.
@interface GSNetworkConfig : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

///  Return a shared config object.
+ (GSNetworkConfig *)sharedConfig;

///  Request base URL, such as "http://www.BRBR Co., LTD". Default is empty string.
@property (nonatomic, copy) NSString *baseURL;
///  Request CDN URL. Default is empty string.
@property (nonatomic, copy) NSString *cdnURL;
///  URL filters. See also `GSURLFilterProtocol`.
@property (nonatomic, strong, readonly) NSArray<id<GSURLFilterProtocol>> *urlFilters;
///  Cache path filters. See also `GSCacheDirPathFilterProtocol`.
@property (nonatomic, strong, readonly) NSArray<id<GSCacheDirPathFilterProtocol>> *cacheDirPathFilters;
///  Security policy will be used by AFNetworking. See also `AFSecurityPolicy`.
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;
///  Whether to log debug info. Default is NO;
@property (nonatomic) BOOL debugLogEnabled;
/// Whether to log request headers. Default is NO;
@property (nonatomic) BOOL needRequstHeaderLog;
///  SessionConfiguration will be used to initialize AFHTTPSessionManager. Default is nil.
@property (nonatomic, strong) NSURLSessionConfiguration* sessionConfiguration;

///  Add a new URL filter.
- (void)addUrlFilter:(id<GSURLFilterProtocol>)filter;
///  Remove all URL filters.
- (void)clearUrlFilter;
///  Add a new cache path filter
- (void)addCacheDirPathFilter:(id<GSCacheDirPathFilterProtocol>)filter;
///  Clear all cache path filters.
- (void)clearCacheDirPathFilter;

@end

NS_ASSUME_NONNULL_END
