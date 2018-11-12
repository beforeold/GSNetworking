//
//  GSRootRequest.h
//
//  Copyright (c)  BRBR Co.ltd

#import <Foundation/Foundation.h>
#import "GSNetworkEnum.h"
#import "GSNetworkingConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const GSRequestValidationErrorDomain;

NS_ENUM(NSInteger) {
    GSRequestValidationErrorInvalidStatusCode = -8,
    GSRequestValidationErrorInvalidJSONFormat = -9,
    GSRequestValidationErrorInvalidResponseObject = -10,
};

///  Request priority
typedef NS_ENUM(NSInteger, GSRequestPriority) {
    GSRequestPriorityLow = -4L,
    GSRequestPriorityDefault = 0,
    GSRequestPriorityHigh = 4,
};

@protocol AFMultipartFormData;

typedef void (^AFConstructingBlock)(id<AFMultipartFormData> formData);
typedef void (^AFURLSessionTaskProgressBlock)(NSProgress *);

@class GSRootRequest;

typedef void(^GSRequestSuccessBlock)(__kindof GSRootRequest *request, id reponseObject);
typedef void(^GSRequestCompletionBlock)(__kindof GSRootRequest *request);

///  The GSRequestDelegate protocol defines several optional methods you can use
///  to receive network-related messages. All the delegate methods will be called
///  on the main queue.
@protocol GSRequestDelegate <NSObject>

@optional
///  Tell the delegate that the request has finished successfully.
///
///  @param request The corresponding request.
- (void)requestFinished:(__kindof GSRootRequest *)request;

///  Tell the delegate that the request has failed.
///
///  @param request The corresponding request.
- (void)requestFailed:(__kindof GSRootRequest *)request;

@end

///  The GSRequestAccessory protocol defines several optional methods that can be
///  used to track the status of a request. Objects that conforms this protocol
///  ("accessories") can perform additional configurations accordingly. All the
///  accessory methods will be called on the main queue.
@protocol GSRequestAccessory <NSObject>

@optional

///  Inform the accessory that the request is about to start.
///
///  @param request The corresponding request.
- (void)requestWillStart:(id)request;

///  Inform the accessory that the request is about to stop. This method is called
///  before executing `requestFinished` and `successCompletionBlock`.
///
///  @param request The corresponding request.
- (void)requestWillStop:(id)request;

///  Inform the accessory that the request has already stoped. This method is called
///  after executing `requestFinished` and `successCompletionBlock`.
///
///  @param request The corresponding request.
- (void)requestDidStop:(id)request;

@end

/// !!TODO The default implementation should be declared
///  RootRequest is the abstract class of network request. It provides many options
///  for constructing request. It's the base class of `GSRequest`.
@interface GSRootRequest : NSObject

#pragma mark - Request and Response Information
///=============================================================================
/// @name Request and Response Information
///=============================================================================

///  The underlying NSURLSessionTask.
///
///  @warning This value is actually nil and should not be accessed before the request starts.
@property (nonatomic, strong, readonly) NSURLSessionTask *requestTask;

///  Shortcut for `requestTask.currentRequest`.
@property (nonatomic, strong, readonly) NSURLRequest *currentRequest;

///  Shortcut for `requestTask.originalRequest`.
@property (nonatomic, strong, readonly) NSURLRequest *originalRequest;

///  Shortcut for `requestTask.response`.
@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;

///  The response status code. `response.statusCode`
@property (nonatomic, readonly) NSInteger responseStatusCode;

///  The response header fields. `response.allHeaderFields`
@property (nonatomic, strong, readonly, nullable) NSDictionary *responseHeaders;

///  The raw data representation of response. Note this value can be nil if request failed.
@property (nonatomic, strong, readonly, nullable) NSData *responseData;

///  The string representation of response. Note this value can be nil if request failed.
@property (nonatomic, strong, readonly, nullable) NSString *responseString;

///  This serialized response object. The actual type of this object is determined by
///  `GSResponseSerializerType`. Note this value can be nil if request failed.
///
///  @discussion If `resumableDownloadPath` and DownloadTask is using, this value will
///              be the path to which file is successfully saved (NSURL), or nil if request failed.
@property (nonatomic, strong, readonly, nullable) id responseObject;

///  If you use `GSResponseSerializerTypeJSON`, this is a convenience (and sematic) getter
///  for the response object. Otherwise this value is nil.
@property (nonatomic, strong, readonly, nullable) id responseJSONObject;

///  This error can be either serialization error or network error. If nothing wrong happens
///  this value will be nil.
@property (nonatomic, strong, readonly, nullable) NSError *error;

///  Return cancelled state of request task.
@property (nonatomic, readonly, getter=isCancelled) BOOL cancelled;

///  Executing state of request task.
@property (nonatomic, readonly, getter=isExecuting) BOOL executing;


#pragma mark - Request Configuration
///=============================================================================
/// @name Request Configuration
///=============================================================================

///  Tag can be used to identify request. Default value is 0.
@property (nonatomic) NSInteger tag;

///  The userInfo can be used to store additional info about the request. Default is nil.
@property (nonatomic, strong, nullable) NSDictionary *userInfo;

///  The delegate object of the request. If you choose block style callback you can ignore this.
///  Default is nil.
@property (nonatomic, weak, nullable) id <GSRequestDelegate> delegate;

///  The success callback. Note if this value is not nil and `requestFinished` delegate method is
///  also implemented, both will be executed but delegate method is first called. This block
///  will be called on the main queue.
@property (nonatomic, copy, nullable) GSRequestSuccessBlock successCompletionBlock;

///  The failure callback. Note if this value is not nil and `requestFailed` delegate method is
///  also implemented, both will be executed but delegate method is first called. This block
///  will be called on the main queue.
@property (nonatomic, copy, nullable) GSRequestCompletionBlock failureCompletionBlock;

///  Set completion callbacks
- (void)setCompletionBlockWithSuccess:(nullable GSRequestSuccessBlock)success
                              failure:(nullable GSRequestCompletionBlock)failure;

///  Nil out both success and failure callback blocks.
- (void)clearCompletionBlock;

///  This can be use to construct HTTP body when needed in POST request. Default is nil.
@property (nonatomic, copy, nullable) AFConstructingBlock constructingBodyBlock;

///  This value is used to perform resumable download request. Default is nil.
///
///  @discussion NSURLSessionDownloadTask is used when this value is not nil.
///              The exist file at the path will be removed before the request starts. If request succeed, file will
///              be saved to this path automatically, otherwise the response will be saved to `responseData`
///              and `responseString`. For this to work, server must support `Range` and response with
///              proper `Last-Modified` and/or `Etag`. See `NSURLSessionDownloadTask` for more detail.
@property (nonatomic, strong, nullable) NSString *resumableDownloadPath;

///  You can use this block to track the download progress. See also `resumableDownloadPath`.
@property (nonatomic, copy, nullable) AFURLSessionTaskProgressBlock resumableDownloadProgressBlock;

///  The priority of the request. Effective only on iOS 8+. Default is `GSRequestPriorityDefault`.
@property (nonatomic) GSRequestPriority requestPriority;

///  This can be used to add several accossories object.
@property (nonatomic, strong, nullable) NSMutableArray <id <GSRequestAccessory>> *requestAccessories;

///  Convenience method to add request accessory. See also `requestAccessories`.
- (void)addAccessory:(id<GSRequestAccessory>)accessory;


#pragma mark - Request Action
///=============================================================================
/// @name Request Action
///=============================================================================

///  Append self to request queue and start the request.
- (void)start;

///  Remove self from request queue and cancel the request.
- (void)cancel;

///  Convenience method to start the request with block callbacks.
- (void)startWithSuccess:(nullable GSRequestSuccessBlock)success
                 failure:(nullable GSRequestCompletionBlock)failure;

- (void)startWithSuccess:(nullable GSRequestSuccessBlock)success;


#pragma mark - Subclass Override
///=============================================================================
/// @name Subclass Override
///=============================================================================

/// identifier for this api's service
/// this will determine the baseURL
/// @see `baseURL`
- (NSString *)serviceIdentifier;

///  The URL path of request. This should only contain the path part of URL, e.g., /v1/user. See alse `baseURL`.
///
///  @discussion This will be concated with `baseURL` using [NSURL URLWithString:relativeToURL].
///              Because of this, it is recommended that the usage should stick to rules stated above.
///              Otherwise the result URL may not be correctly formed. See also `URLString:relativeToURL`
///              for more information.
///
///              Additionally, if `requestURL` itself is a valid URL, it will be used as the result URL and
///              `baseURL` will be ignored.
- (NSString *)requestURL;

///  Additional request params for URLRequest.
- (nullable id)requestParams;

@property (nonatomic, strong, readonly) id finalRequestParams;

///  Called on background thread after request succeded just before switching to main thread.
///  Note if cache is loaded, this method WILL be called on the main thread, just like `requestCompleteFilter`.
///  !!TODO ....RootRequest Should not know anything about cache.
- (void)requestCompletePreprocessor;

///  Called on the main thread after request succeeded.
- (void)requestCompleteFilter;

///  Called on background thread after request succeded but before switching to main thread. See also
///  `requestCompletePreprocessor`.
- (void)requestFailedPreprocessor;

///  Called on the main thread when request failed.
- (void)requestFailedFilter;

///  The baseURL of request. This should only contain the host part of URL, e.g., http://www.example.com.
///  See also `requestURL`
///  Default value depends on `serviceIdentifier`
- (NSString *)baseURL;

///  Requset timeout interval.
///  Default value depends on `serviceIdentifier`
///
///  @discussion When using `resumableDownloadPath`(NSURLSessionDownloadTask), the session seems to completely ignore
///              `timeoutInterval` property of `NSURLRequest`. One effective way to set timeout would be using
///              `timeoutIntervalForResource` of `NSURLSessionConfiguration`.
@property (nonatomic, assign) NSTimeInterval requestTimeoutInterval;

///  Override this method to filter requests with certain arguments when caching.
- (id)cacheFileNameFilterForRequestParams:(id)params;

///  HTTP request method.
///  Default value depends on `serviceIdentifier`
- (GSRequestMethod)requestMethod;

///  Request serializer type.
///  Default value depends on `serviceIdentifier`
- (GSRequestSerializerType)requestSerializerType;

///  Response serializer type. See also `responseObject`.
///  Default value depends on `serviceIdentifier`
- (GSResponseSerializerType)responseSerializerType;

///  Username and password used for HTTP authorization. Should be formed as @[@"Username", @"Password"].
- (nullable NSArray<NSString *> *)requestAuthorizationHeaderFieldArray;

///  Additional HTTP request header field.
- (nullable NSDictionary<NSString *, NSString *> *)requestHeaderFields;

///  Should use CDN when sending request. Default is NO
- (BOOL)useCDN;

///  Optional CDN URL for request.
- (NSString *)cdnURL;

///  Whether the request is allowed to use the cellular radio (if present). Default is YES.
- (BOOL)allowsCellularAccess;

#pragma mark Validator

///  The validator will be used to test whether `responseJSONObject` is correctly formed.
///  And decide the success result of request call back
///  Default is nil, do nothing
///  example code
///  return @{
///  @"nick": [NSString class],
///  @"level": [NSNumber class]
///  };
- (nullable id)validatorForJSONObject;

///  This  will test whether `responseStatusCode` is valid.
///  And decide the success result of request call back
- (BOOL)validateStatusCode;

/// This will test whether `responseObject` is valid
///  And decide the success result of request call back
/// You should always call super
/// 校验 responseObject 是否合理，在 service 校验之后，可以返回指定的错误信息
- (BOOL)validateResponseObjectWithError:(NSError **)error;

/// 记录请求处理过程中的日志，并在回调完成后统一打印
@property (nonatomic, strong, readonly) NSMutableString *progressLog;

@end
    
    NS_ASSUME_NONNULL_END
