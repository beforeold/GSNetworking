//
//  GSRequest.h
//
//  Copyright (c)  BRBR Co.ltd

#import "GSRootRequest.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const GSRequestCacheErrorDomain;

typedef NS_ENUM(NSInteger, GSRequestCacheError) {
    GSRequestCacheErrorExpired = -1,
    GSRequestCacheErrorVersionMismatch = -2,
    GSRequestCacheErrorSensitiveDataMismatch = -3,
    GSRequestCacheErrorAppVersionMismatch = -4,
    GSRequestCacheErrorInvalidCacheTime = -5,
    GSRequestCacheErrorInvalidMetadata = -6,
    GSRequestCacheErrorInvalidCacheData = -7,
};

/// ------------------------------------------------------------------
/// 自定义成功回调的模型类型 - Interface
#define OverSuperStartITF(clz, respClz) \
- (void)startWithSuccess:(void (^)(clz *api, respClz *result))success failure:(void (^)(clz *api))failure;\
- (void)startWithSuccess:(void (^)(clz *api, respClz *result))success;

/// 自定义成功回调的模型类型 - IMP
#define OverSuperStartIMP(clz, respClz) \
- (void)startWithSuccess:(void (^)(clz *api, respClz *result))success failure:(void (^)(clz *api))failure { \
    [super startWithSuccess:^(__kindof GSRootRequest * _Nonnull requestSuper, id  _Nonnull reponseObject) { \
        !success ?: success(requestSuper, ((GSRequest *)requestSuper).modelledResult); \
    } failure:failure]; \
}\
\
- (void)startWithSuccess:(void (^)(clz *api, respClz *result))success { \
    [self startWithSuccess:success failure:nil]; \
}\

#define OverSuperStartIMP_NS(clz, respClz) \
- (void)startWithSuccess:(void (^)(clz *api, respClz *result))success failure:(void (^)(clz *api))failure { \
    [super startWithSuccess:^(__kindof GSRootRequest * _Nonnull requestSuper, id  _Nonnull reponseObject) { \
        !success ?: success(requestSuper, ((GSRequest *)requestSuper).responseObject); \
    } failure:failure]; \
}\
\
- (void)startWithSuccess:(void (^)(clz *api, respClz *result))success { \
    [self startWithSuccess:success failure:nil]; \
}\

/// ------------------------------------------------------------------
/// 无返回值的接口定义 - Interface
#define OverSuperStarITF_0(clz) \
- (void)startWithSuccess:(void (^)(clz *api))success failure:(void (^)(clz *api))failure;\
- (void)startWithSuccess:(void (^)(clz *api))success;

/// 无返回值的实现定义 -  IMP
#define OverSuperStarIMP_0(clz) \
- (void)startWithSuccess:(void (^)(clz *api))success failure:(void (^)(clz *api))failure { \
    [super startWithSuccess:^(__kindof GSRootRequest * _Nonnull request, id  _Nonnull reponseObject) { \
        !success ?: success(request); \
    } failure:failure]; \
} \
\
- (void)startWithSuccess:(void (^)(clz *api))success { \
    [self startWithSuccess:success failure:nil]; \
}\


/// ------------------------------------------------------------------
/// 便利构造方法 - Interface
#define BuildWithParamITF(clz) \
- (instancetype)initWithParam:(clz *)param;

/// 便利构造方法 - IMP
#define BuildWithParamIMP(clz) \
- (instancetype)initWithParam:(clz *)param { \
    self = [super init]; \
    if (self) { \
        self.modelledParams = param; \
    } \
\
    return self;\
}\

///  GSRequest is the base class you should inherit to create your own request class.
///  Based on RootRequest, GSRequest adds local caching feature. Note download
///  request will not be cached whatsoever, because download request may involve complicated
///  cache control policy controlled by `Cache-Control`, `Last-Modified`, etc.
@interface GSRequest : GSRootRequest

///  Whether to use cache as response or not.
///  Default is NO, which means caching will take effect with specific arguments.
///  Note that `cacheTimeInSeconds` default is -1. As a result cache data is not actually
///  used as response unless you return a positive value in `cacheTimeInSeconds`.
///
///  Also note that this option does not affect storing the response, which means response will always be saved
///  even `ignoreCache` is YES.
@property (nonatomic) BOOL ignoreCache;

/// Parameters which has been modelled, if set, it will be unmodelled to `rawParams`
@property (nonatomic, strong) id modelledParams;

/// This is the raw Bussineess JSONObject params, will be used for reform
@property (nonatomic, strong) id rawParams;

///  Whether data is from local cache.
- (BOOL)isDataFromCache;

///  Manually load cache from storage.
///
///  @param error If an error occurred causing cache loading failed, an error object will be passed, otherwise NULL.
///
///  @return Whether cache is successfully loaded.
- (BOOL)loadCacheWithError:(NSError * __autoreleasing *)error;

///  Start request without reading local cache even if it exists. Use this to update local cache.
- (void)startWithoutCache;

/// Save response data (probably from another request) to this request's cache location
- (void)saveResponseDataToCacheFile:(NSData *)data;

#pragma mark - Subclass Override

/// `rawParams` will be send to reform, default return `rawParams`
- (id)reformRequestParams:(id)requestParams;

/// reform responseObject before call back, default return the method parameter itself
- (id)reformResponseObject:(id)responseObject;


/// Class for response model (maybe in array) if set responeObject will be modelled
@property (nonatomic, strong, readonly) Class respModelClass;

/// 模型化的返回值
@property (nonatomic, strong, readonly) id modelledResult;


/// 页数，默认为 nil
@property (nonatomic, strong) NSNumber *page;
/// page 对应的请求参数，默认为 `page`
@property (nonatomic, copy, readonly) NSString *pageKeyPath;
/// 上下拉刷新调用网络请求后需要执行的回调
@property (nonatomic, copy, nullable) void(^refreshCompletion)(BOOL succeed, NSUInteger count);
/// 是否为下拉刷新，默认为 NO
@property (nonatomic, assign) BOOL isRefresh;
/// 是否为强制刷新，可以显示 hud，默认为 NO
@property (nonatomic, assign) BOOL isForce;
/// list类型的返回结果中对象数量，如果是数组则自动获取，否则子类成 override 实现。
- (NSUInteger)countOfListInReponseObject:(id)reponseObject;

/// 错误信息的描述，（包含业务信息，取决于 request / service 的校验结果 error）
@property (nonatomic, copy, readonly, nullable) NSString *errorMsg;


/// Expected result type for response model, none / one / list, used for response modelling
- (GSExpectedResultType)expectedResultType;

///  The max time duration that cache can stay in disk until it's considered expired.
///  Default is -1, which means response is not actually saved as cache.
- (NSInteger)cacheTimeInSeconds;

///  Version can be used to identify and invalidate local cache. Default is 0.
- (long long)cacheVersion;

///  This can be used as additional identifier that tells the cache needs updating.
///
///  @discussion The `description` string of this object will be used as an identifier to verify whether cache
///              is invalid. Using `NSArray` or `NSDictionary` as return value type is recommended. However,
///              If you intend to use your custom class type, make sure that `description` is correctly implemented.
- (nullable id)cacheSensitiveData;

///  Whether cache is asynchronously written to storage. Default is YES.
- (BOOL)writeCacheAsynchronously;

@end

NS_ASSUME_NONNULL_END
