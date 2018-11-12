//
//  GSRequest.m
//
//  Copyright (c)  BRBR Co.ltd

#import "GSNetworkConfig.h"
#import "GSRequest.h"
#import "GSNetworkPrivate.h"

#ifndef NSFoundationVersionNumber_iOS_8_0
#define NSFoundationVersionNumber_With_QoS_Available 1140.11
#else
#define NSFoundationVersionNumber_With_QoS_Available NSFoundationVersionNumber_iOS_8_0
#endif

NSString *const GSRequestCacheErrorDomain = @"com.yuantiku.request.caching";

static dispatch_queue_t GSRequest_cache_writing_queue() {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_attr_t attr = DISPATCH_QUEUE_SERIAL;
        if (NSFoundationVersionNumber >= NSFoundationVersionNumber_With_QoS_Available) {
            attr = dispatch_queue_attr_make_with_qos_class(attr, QOS_CLASS_BACKGROUND, 0);
        }
        queue = dispatch_queue_create("com.yuantiku.GSRequest.caching", attr);
    });
    
    return queue;
}

@interface GSCacheMetadata : NSObject<NSSecureCoding>

@property (nonatomic, assign) long long version;
@property (nonatomic, copy) NSString *sensitiveDataString;
@property (nonatomic, assign) NSStringEncoding stringEncoding;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, copy) NSString *appVersionString;

@end

@implementation GSCacheMetadata

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:@(self.version) forKey:NSStringFromSelector(@selector(version))];
    [aCoder encodeObject:self.sensitiveDataString forKey:NSStringFromSelector(@selector(sensitiveDataString))];
    [aCoder encodeObject:@(self.stringEncoding) forKey:NSStringFromSelector(@selector(stringEncoding))];
    [aCoder encodeObject:self.creationDate forKey:NSStringFromSelector(@selector(creationDate))];
    [aCoder encodeObject:self.appVersionString forKey:NSStringFromSelector(@selector(appVersionString))];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (!self) {
        return nil;
    }
    
    self.version = [[aDecoder decodeObjectOfClass:[NSNumber class]
                                           forKey:NSStringFromSelector(@selector(version))] integerValue];
    self.sensitiveDataString = [aDecoder decodeObjectOfClass:[NSString class]
                                                      forKey:NSStringFromSelector(@selector(sensitiveDataString))];
    self.stringEncoding = [[aDecoder decodeObjectOfClass:[NSNumber class]
                                                  forKey:NSStringFromSelector(@selector(stringEncoding))] integerValue];
    self.creationDate = [aDecoder decodeObjectOfClass:[NSDate class]
                                               forKey:NSStringFromSelector(@selector(creationDate))];
    self.appVersionString = [aDecoder decodeObjectOfClass:[NSString class]
                                                   forKey:NSStringFromSelector(@selector(appVersionString))];
    
    return self;
}

@end

@interface GSRequest()

@property (nonatomic, strong) NSData *cacheData;
@property (nonatomic, copy) NSString *cacheString;
@property (nonatomic, strong) id cacheJSON;
@property (nonatomic, strong) NSXMLParser *cacheXML;

@property (nonatomic, strong) GSCacheMetadata *cacheMetadata;
@property (nonatomic, assign) BOOL dataFromCache;
@property (nonatomic, strong, readwrite) id modelledResult;

/// 是否为分页的子请求
@property (nonatomic, assign) BOOL isChild;

@end

@implementation GSRequest
#pragma mark - Superclass Override
- (void)start {
    if (self.ignoreCache) {
        [self startWithoutCache];
        return;
    }
    
    // Do not cache download request.
    if (self.resumableDownloadPath) {
        [self startWithoutCache];
        return;
    }
    
    if (![self loadCacheWithError:nil]) {
        [self startWithoutCache];
        return;
    }
    
    _dataFromCache = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self requestCompletePreprocessor];
        [self requestCompleteFilter];
        GSRequest *strongSelf = self;
        [strongSelf.delegate requestFinished:strongSelf];
        if (strongSelf.successCompletionBlock) {
            strongSelf.successCompletionBlock(strongSelf, strongSelf.responseObject);
        }
        [strongSelf clearCompletionBlock];
    });
}

- (id)requestParams {
    [self jsonSerialRequestParamModelIfNeeded];
    
    id reformedParams = [self reformRequestParams:self.rawParams];
    
    if (self.page && [reformedParams isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:reformedParams];
        dic[self.pageKeyPath] = self.page;
        reformedParams = dic;
    }
    
    return reformedParams;
}

- (NSString *)pageKeyPath {
    return @"page";
}

- (id)reformRequestParams:(id)requestParams {
    return requestParams;
}

- (id)reformResponseObject:(id)responseObject {
    return responseObject;
}

- (void)jsonSerialRequestParamModelIfNeeded {
    if (self.modelledParams) {
        id <GSHTTPServiceProtocol> child = self.service.child;
        if ([child respondsToSelector:@selector(modelToJSONObject:)]) {
            self.rawParams = [child modelToJSONObject:self.modelledParams];
        }
    }
}

- (BOOL)validateResponseObjectWithError:(NSError * _Nullable __autoreleasing *)error {
    self.responseObject = [self reformResponseObject:self.responseObject];
    if ([self expectedResultType] == GSExpectedResultTypeNone) return YES;
    
    if (self.respModelClass) {
        id <GSHTTPServiceProtocol> child = self.service.child;
        if ([child respondsToSelector:@selector(modelWithResponseObject:class:expectedResultType:error:)]) {
            NSError *modelError = nil;
            id model = [child modelWithResponseObject:self.responseObject
                                                class:self.respModelClass
                                   expectedResultType:[self expectedResultType]
                                                error:&modelError];
            self.modelledResult = model;
            if (error)  *error = modelError;
            return modelError == nil;
        }
    }
    
    return YES;
}

/// 获取错误信息
- (NSString *)errorMsg {
    if (!self.error) return nil;
        
    NSString *msg = self.error.localizedDescription;
    return msg;
}

#pragma mark - Network Request Delegate
- (void)requestCompletePreprocessor {
    [super requestCompletePreprocessor];
    
    if (self.writeCacheAsynchronously) {
        dispatch_async(GSRequest_cache_writing_queue(), ^{
            [self saveResponseDataToCacheFile:[super responseData]];
        });
    } else {
        [self saveResponseDataToCacheFile:[super responseData]];
    }
}

#pragma mark - Subclass Override
- (GSExpectedResultType)expectedResultType {
    return GSExpectedResultTypeNone;
}

- (NSInteger)cacheTimeInSeconds {
    return -1;
}

- (long long)cacheVersion {
    return 0;
}

- (id)cacheSensitiveData {
    return nil;
}

- (BOOL)writeCacheAsynchronously {
    return YES;
}

#pragma mark -

- (BOOL)isDataFromCache {
    return _dataFromCache;
}

- (NSData *)responseData {
    if (_cacheData) {
        return _cacheData;
    }
    return [super responseData];
}

- (NSString *)responseString {
    if (_cacheString) {
        return _cacheString;
    }
    return [super responseString];
}

- (id)responseJSONObject {
    if (_cacheJSON) {
        return _cacheJSON;
    }
    return [super responseJSONObject];
}

- (id)responseObject {
    if (_cacheJSON) {
        return _cacheJSON;
    }
    if (_cacheXML) {
        return _cacheXML;
    }
    if (_cacheData) {
        return _cacheData;
    }
    return [super responseObject];
}

#pragma mark -

- (BOOL)loadCacheWithError:(NSError * _Nullable __autoreleasing *)error {
    // Make sure cache time in valid.
    if ([self cacheTimeInSeconds] < 0) {
        if (error) {
            *error = [NSError errorWithDomain:GSRequestCacheErrorDomain
                                         code:GSRequestCacheErrorInvalidCacheTime
                                     userInfo:@{ NSLocalizedDescriptionKey:@"Invalid cache time"}];
        }
        return NO;
    }
    
    // Try load metadata.
    if (![self loadCacheMetadata]) {
        if (error) {
            *error = [NSError errorWithDomain:GSRequestCacheErrorDomain
                                         code:GSRequestCacheErrorInvalidMetadata
                                     userInfo:@{ NSLocalizedDescriptionKey:@"Invalid metadata. Cache may not exist"}];
        }
        return NO;
    }
    
    // Check if cache is still valid.
    if (![self validateCacheWithError:error]) {
        return NO;
    }
    
    // Try load cache.
    if (![self loadCacheData]) {
        if (error) {
            *error = [NSError errorWithDomain:GSRequestCacheErrorDomain
                                         code:GSRequestCacheErrorInvalidCacheData
                                     userInfo:@{ NSLocalizedDescriptionKey:@"Invalid cache data"}];
        }
        return NO;
    }
    
    return YES;
}

- (BOOL)validateCacheWithError:(NSError * _Nullable __autoreleasing *)error {
    // Date
    NSDate *creationDate = self.cacheMetadata.creationDate;
    NSTimeInterval duration = -[creationDate timeIntervalSinceNow];
    if (duration < 0 || duration > [self cacheTimeInSeconds]) {
        if (error) {
            *error = [NSError errorWithDomain:GSRequestCacheErrorDomain
                                         code:GSRequestCacheErrorExpired
                                     userInfo:@{ NSLocalizedDescriptionKey:@"Cache expired"}];
        }
        return NO;
    }
    // Version
    long long cacheVersionFileContent = self.cacheMetadata.version;
    if (cacheVersionFileContent != [self cacheVersion]) {
        if (error) {
            *error = [NSError errorWithDomain:GSRequestCacheErrorDomain
                                         code:GSRequestCacheErrorVersionMismatch
                                     userInfo:@{ NSLocalizedDescriptionKey:@"Cache version mismatch"}];
        }
        return NO;
    }
    // Sensitive data
    NSString *sensitiveDataString = self.cacheMetadata.sensitiveDataString;
    NSString *currentSensitiveDataString = ((NSObject *)[self cacheSensitiveData]).description;
    if (sensitiveDataString || currentSensitiveDataString) {
        // If one of the strings is nil, short-circuit evaluation will trigger
        if (sensitiveDataString.length != currentSensitiveDataString.length ||
            ![sensitiveDataString isEqualToString:currentSensitiveDataString]) {
            if (error) {
                *error = [NSError errorWithDomain:GSRequestCacheErrorDomain
                                             code:GSRequestCacheErrorSensitiveDataMismatch
                                         userInfo:@{ NSLocalizedDescriptionKey:@"Cache sensitive data mismatch"}];
            }
            return NO;
        }
    }
    // App version
    NSString *appVersionString = self.cacheMetadata.appVersionString;
    NSString *currentAppVersionString = [GSNetworkUtils appVersionString];
    if (appVersionString || currentAppVersionString) {
        if (appVersionString.length != currentAppVersionString.length ||
            ![appVersionString isEqualToString:currentAppVersionString]) {
            if (error) {
                *error = [NSError errorWithDomain:GSRequestCacheErrorDomain
                                             code:GSRequestCacheErrorAppVersionMismatch
                                         userInfo:@{ NSLocalizedDescriptionKey:@"App version mismatch"}];
            }
            return NO;
        }
    }
    return YES;
}

- (BOOL)loadCacheMetadata {
    NSString *path = [self cacheMetadataFilePath];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path isDirectory:nil]) {
        @try {
            _cacheMetadata = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
            return YES;
        } @catch (NSException *exception) {
            GSNLog(@"Load cache metadata failed, reason = %@", exception.reason);
            return NO;
        }
    }
    return NO;
}

- (BOOL)loadCacheData {
    NSString *path = [self cacheFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    if ([fileManager fileExistsAtPath:path isDirectory:nil]) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        _cacheData = data;
        _cacheString = [[NSString alloc] initWithData:_cacheData encoding:self.cacheMetadata.stringEncoding];
        switch (self.responseSerializerType) {
            case GSResponseSerializerTypeHTTP:
                // Do nothing.
                return YES;
            case GSResponseSerializerTypeJSON:
                _cacheJSON = [NSJSONSerialization JSONObjectWithData:_cacheData
                                                             options:(NSJSONReadingOptions)0
                                                               error:&error];
                return error == nil;
            case GSResponseSerializerTypeXMLParser:
                _cacheXML = [[NSXMLParser alloc] initWithData:_cacheData];
                return YES;
        }
    }
    
    return NO;
}

- (void)saveResponseDataToCacheFile:(NSData *)data {
    if ([self cacheTimeInSeconds] > 0 && ![self isDataFromCache]) {
        if (data != nil) {
            @try {
                // New data will always overwrite old data.
                [data writeToFile:[self cacheFilePath] atomically:YES];
                
                GSCacheMetadata *metadata = [[GSCacheMetadata alloc] init];
                metadata.version = [self cacheVersion];
                metadata.sensitiveDataString = ((NSObject *)[self cacheSensitiveData]).description;
                metadata.stringEncoding = [GSNetworkUtils stringEncodingWithRequest:self];
                metadata.creationDate = [NSDate date];
                metadata.appVersionString = [GSNetworkUtils appVersionString];
                [NSKeyedArchiver archiveRootObject:metadata toFile:[self cacheMetadataFilePath]];
            } @catch (NSException *exception) {
                GSNLog(@"Save cache failed, reason = %@", exception.reason);
            }
        }
    }
}

- (void)clearCacheVariables {
    _cacheData = nil;
    _cacheXML = nil;
    _cacheJSON = nil;
    _cacheString = nil;
    _cacheMetadata = nil;
    _dataFromCache = NO;
}

#pragma mark -
- (void)createDirectoryIfNeeded:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if (![fileManager fileExistsAtPath:path isDirectory:&isDir]) {
        [self createBaseDirectoryAtPath:path];
    } else {
        if (!isDir) {
            NSError *error = nil;
            [fileManager removeItemAtPath:path error:&error];
            [self createBaseDirectoryAtPath:path];
        }
    }
}

- (void)createBaseDirectoryAtPath:(NSString *)path {
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES
                                               attributes:nil error:&error];
    if (error) {
        GSNLog(@"create cache directory failed, error = %@", error);
    } else {
        [GSNetworkUtils addDoNotBackupAttribute:path];
    }
}

- (NSString *)cacheBasePath {
    NSString *pathOfLibrary = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [pathOfLibrary stringByAppendingPathComponent:@"LazyRequestCache"];
    
    // Filter cache base path
    NSArray<id<GSCacheDirPathFilterProtocol>> *filters = [[GSNetworkConfig sharedConfig] cacheDirPathFilters];
    if (filters.count > 0) {
        for (id<GSCacheDirPathFilterProtocol> f in filters) {
            path = [f filterCacheDirPath:path withRequest:self];
        }
    }
    
    [self createDirectoryIfNeeded:path];
    
    return path;
}

- (NSString *)cacheFileName {
    NSString *requestURL = [self requestURL];
    NSString *baseUrl = [GSNetworkConfig sharedConfig].baseURL;
    id argument = [self cacheFileNameFilterForRequestParams:[self requestParams]];
    NSString *requestInfo = [NSString stringWithFormat:@"Method:%ld Host:%@ Url:%@ Argument:%@",
                             (long)[self requestMethod], baseUrl, requestURL, argument];
    NSString *cacheFileName = [GSNetworkUtils md5StringFromString:requestInfo];
    return cacheFileName;
}

- (NSString *)cacheFilePath {
    NSString *cacheFileName = [self cacheFileName];
    NSString *path = [self cacheBasePath];
    path = [path stringByAppendingPathComponent:cacheFileName];
    return path;
}

- (NSString *)cacheMetadataFilePath {
    NSString *cacheMetadataFileName = [NSString stringWithFormat:@"%@.metadata", [self cacheFileName]];
    NSString *path = [self cacheBasePath];
    path = [path stringByAppendingPathComponent:cacheMetadataFileName];
    return path;
}

#pragma mark - Private
- (void)startWithoutCache {
    [self clearCacheVariables];
    
    [self handleStart];
}

/// 处理分页时的开始请求
- (void)handleStart {
    // 不是分页直接开始
    if(!self.page) {
        [super start];
        return;
    }
    
    /// 分页的子请求直接开始
    if (self.isChild) {
        [super start];
        return;
    }
    
    /// 分页的管理者，创建子请求开始
    GSRequest *request = [[[self class] alloc] init];
    request.isChild = YES;
    
    // Brook: 暂时只传递几个常用的字段
    request.page = self.page;
    request.rawParams = self.rawParams;
    request.modelledParams = self.modelledParams;
    request.successCompletionBlock = [GSRequest bindRefreshWithSuccess:self.successCompletionBlock];
    request.failureCompletionBlock = [GSRequest bindRefreshWithFailure:self.failureCompletionBlock];
    request.refreshCompletion = self.refreshCompletion;
    request.requestAccessories = self.requestAccessories;
    request.isRefresh = self.isRefresh;
    request.isForce = self.isForce;
    
    request.delegate = self.delegate;
    request.userInfo = self.userInfo;
    request.requestPriority = self.requestPriority;
    request.ignoreCache = self.ignoreCache;
    request.requestTimeoutInterval = request.requestTimeoutInterval;
    
    [request start];
    
    /// refresh 的 block 可以释放，其他的 block 还是要重用做传递给子请求，不可释放。
    self.refreshCompletion = nil;
}

/// 针对分页请求直接调用 start 方法时不会发起请求，只是设置参数
- (void)startWithSuccess:(GSRequestSuccessBlock)success failure:(GSRequestCompletionBlock)failure {
    if (self.page) {
        [self setCompletionBlockWithSuccess:success failure:failure];
    } else {
        [super startWithSuccess:success failure:failure];
    }
}

#pragma mark - setter/getter
/// 注意这里是采用组合的方式，而摈弃了早一个版本的复写 setter 方法的形式
/// 需要注意一个是 回调的是子请求的实例
/// 再一个是在对子请求的 block 进行赋值时，应该绑定父请求所设置的初始成功/失败 block。
+ (GSRequestSuccessBlock)bindRefreshWithSuccess:(GSRequestSuccessBlock)successCompletionBlock {
    GSRequestSuccessBlock success = successCompletionBlock;
    
    success = ^(GSRequest *request, id responseObject){
        !successCompletionBlock ?: successCompletionBlock(request, responseObject);
        
        NSInteger count = [request countOfListInReponseObject:responseObject];
        !request.refreshCompletion ?: request.refreshCompletion(YES, count);
        request.refreshCompletion = nil;
    };
    
    return success;
}

+ (GSRequestCompletionBlock)bindRefreshWithFailure:(GSRequestCompletionBlock)failureCompletionBlock {
    GSRequestCompletionBlock failure = failureCompletionBlock;
    failure = ^(GSRequest *request){
        !failureCompletionBlock ?: failureCompletionBlock(request);
        
        !request.refreshCompletion ?: request.refreshCompletion(NO, 0);
        request.refreshCompletion = nil;
    };
    
    return failure;
}

- (void)list {
    NSLog(@" to dismiss warning");
}

- (NSUInteger)countOfListInReponseObject:(id)reponseObject {
    if ([self.modelledResult isKindOfClass:[NSArray class]]) {
        return [self.modelledResult count];
    }
    
    if ([self.modelledResult respondsToSelector:@selector(list)]) {
        id ret = [self.modelledResult performSelector:@selector(list)];
        if ([ret isKindOfClass:[NSArray class]]) {
            return [ret count];
        }
    }
    
    if ([reponseObject isKindOfClass:[NSArray class]]) {
        return [reponseObject count];
    }
    
    return 0;
}

@end
