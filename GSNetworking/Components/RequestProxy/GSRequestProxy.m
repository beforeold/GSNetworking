
//
//  GSNetworkAgent.m
//
//  Copyright (c)  BRBR Co.ltd

#import "GSRequestProxy.h"
#import "GSNetworkConfig.h"
#import "GSNetworkPrivate.h"
#import <pthread/pthread.h>
#import "GSRequestGenerator.h"
#import "GSHTTPServiceCenter.h"
#import "GSJSONResponseSerializer.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

#define kGSNetworkIncompleteDownloadFolderName @"Incomplete"

@interface GSRequestProxy () <GSJSONResponseSerializerDelegate>

@property (nonatomic, strong) NSMutableDictionary *sessionManagerCache;

@end

@implementation GSRequestProxy {
    GSJSONResponseSerializer *_jsonResponseSerializer;
    NSMutableDictionary<NSNumber *, GSRootRequest *> *_requestsRecord;
    
    dispatch_queue_t _processingQueue;
    pthread_mutex_t _lock;
}

#pragma mark - Lifecycle & Public methods
+ (GSRequestProxy *)sharedProxy {
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
        _requestsRecord = [NSMutableDictionary dictionary];
        _processingQueue = dispatch_queue_create("com.BRBR.goodsSearch.processing", DISPATCH_QUEUE_CONCURRENT);
        
        _jsonResponseSerializer = [[GSJSONResponseSerializer alloc] init];
        _jsonResponseSerializer.delegate = self;
        
        
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

- (void)addRequest:(GSRootRequest *)request {
    NSParameterAssert(request != nil);
    if (!request) return;
    NSError * __autoreleasing serializationError = nil;
    [request.progressLog deleteCharactersInRange:NSMakeRange(0, request.progressLog.length)];
    request.requestTask = [self prepareTaskForRequest:request error:&serializationError];
    if (serializationError) {
        [self handleFailedRequest:request error:serializationError];
        return;
    }
    
    NSAssert(request.requestTask != nil, @"requestTask should not be nil");
    
    // Set request task priority
    // !!Available on iOS 8 +
    if ([request.requestTask respondsToSelector:@selector(priority)]) {
        switch (request.requestPriority) {
            case GSRequestPriorityHigh:
                request.requestTask.priority = NSURLSessionTaskPriorityHigh;
                break;
            case GSRequestPriorityLow:
                request.requestTask.priority = NSURLSessionTaskPriorityLow;
                break;
            case GSRequestPriorityDefault:
                /*!!fall through*/
            default:
                request.requestTask.priority = NSURLSessionTaskPriorityDefault;
                break;
        }
    }
    
    // Retain request
    [self recordRequest:request];
    [request.requestTask resume];
}

- (void)cancelRequest:(GSRootRequest *)request {
    NSParameterAssert(request != nil);
    
    [request.requestTask cancel];
    [self removeRequest:request];
    [request clearCompletionBlock];
}

- (void)cancelAllRequests {
    Lock();
    NSArray *allKeys = [_requestsRecord allKeys];
    Unlock();
    if (allKeys && allKeys.count > 0) {
        NSArray *copiedKeys = [allKeys copy];
        for (NSNumber *key in copiedKeys) {
            Lock();
            GSRootRequest *request = _requestsRecord[key];
            Unlock();
            // We are using non-recursive lock.
            // Do not lock `stop`, otherwise deadlock may occur.
            [request cancel];
        }
    }
}

#pragma mark - AFN callback
- (void)handleRequestResult:(NSURLSessionTask *)task responseObject:(id)responseObject error:(NSError *)error {
    Lock();
    GSRootRequest *request = _requestsRecord[@([task hash])];
    Unlock();
    
    // When the request is cancelled and removed from records, the underlying
    // AFNetworking failure callback will still kicks in, resulting in a nil `request`.
    //
    // Here we choose to completely ignore cancelled tasks. Neither success or failure
    // callback will be called.
    if (!request) return;
    
    NSString *responseLog = [NSString stringWithFormat:@"\n\
Status code:  %zd --> %@\n\
Response: %@\n\
",
request.responseStatusCode,
[NSHTTPURLResponse localizedStringForStatusCode:request.responseStatusCode] ?: @"-",
[responseObject isKindOfClass:[NSData class]] ? @"-" : (responseObject ?: @"-")];
    [request.progressLog appendString:responseLog];
    
    request.responseObject = responseObject;
    
    BOOL succeed = NO;
    NSError *requestError = nil;
    if (error) {
        succeed = NO;
        requestError = error;
    } else {
        NSError * __autoreleasing validationError = nil;
        succeed = [self validateResult:request error:&validationError];
        requestError = validationError;
    }
    
    if (succeed) {
        [self handleSucceededRequest:request];
        
    } else {
        [self handleFailedRequest:request error:requestError];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeRequest:request];
        [request clearCompletionBlock];
    });
}

- (void)handleSucceededRequest:(GSRootRequest *)request {
    @autoreleasepool {
        [request requestCompletePreprocessor];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self printLogOfRequest:request];

        [request toggleAccessoriesWillStopCallBack];
        [request requestCompleteFilter];
        
        [request.delegate requestFinished:request];
        if (request.successCompletionBlock) {
            request.successCompletionBlock(request, request.responseObject);
        }
        
        [request toggleAccessoriesDidStopCallBack];
    });
}

/// 打印日志
- (void)printLogOfRequest:(GSRootRequest *)request {
    NSString *endLog = @"\n\
==============================================================\n\
=                        Response End                        =\n\
==============================================================\n\
";
    [request.progressLog appendString:endLog];
    
    GSNLog(@"%@", request.progressLog);
}

/// 处理失败的请求及其回调
- (void)handleFailedRequest:(GSRootRequest *)request error:(NSError *)error {
    NSString *localDesc = error.userInfo[NSLocalizedDescriptionKey];
    if (!localDesc.length) {
        localDesc = @"网络服务异常，请稍后重试";
        
        NSMutableDictionary *fixedUserInfo = [NSMutableDictionary dictionary];
        [fixedUserInfo addEntriesFromDictionary:error.userInfo];
        fixedUserInfo[NSLocalizedDescriptionKey] = localDesc;
        error = [NSError errorWithDomain:error.domain code:error.code userInfo:fixedUserInfo];
    }
    
    request.error = error;
    
    NSString *errorLog = nil;
errorLog = [NSString stringWithFormat:@"\n\
Error: %@ %zd %@\n\
                       😭  😭        😭 😭\n\
                          😭 😭  😭 😭\n\
                             😭  😭\n\
                          😭 😭  😭 😭\n\
                      😭 😭         😭 😭\n\n\
",
error.domain, error.code, error.localizedDescription];
    [request.progressLog appendString:errorLog];
    
    // Save incomplete download data.
    NSData *incompleteDownloadData = error.userInfo[NSURLSessionDownloadTaskResumeData];
    if (incompleteDownloadData) {
        [incompleteDownloadData writeToURL:[self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath]
                                atomically:YES];
    }
    
    // Load response from file and clean up if download task failed.
    if ([request.responseObject isKindOfClass:[NSURL class]]) {
        NSURL *url = request.responseObject;
        if (url.isFileURL && [[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            request.responseData = [NSData dataWithContentsOfURL:url];
            request.responseString = [[NSString alloc] initWithData:request.responseData
                                                           encoding:[GSNetworkUtils stringEncodingWithRequest:request]];
            
            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        }
        request.responseObject = nil;
    }
    
    @autoreleasepool {
        [request requestFailedPreprocessor];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self printLogOfRequest:request];

        [request toggleAccessoriesWillStopCallBack];
        [request requestFailedFilter];
        
        [request.delegate requestFailed:request];
        if (request.failureCompletionBlock) {
            request.failureCompletionBlock(request);
        }
        
        [request toggleAccessoriesDidStopCallBack];
    });
}

- (void)recordRequest:(GSRootRequest *)request {
    Lock();
    _requestsRecord[@([request.requestTask hash])] = request;
    Unlock();
}

- (void)removeRequest:(GSRootRequest *)request {
    Lock();
    [_requestsRecord removeObjectForKey:@([request.requestTask hash])];
    Unlock();
}

#pragma mark - Private methods --> dataTask
- (NSURLSessionTask *)prepareTaskForRequest:(GSRootRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    NSURLRequest *urlRequest = [[GSRequestGenerator sharedGenerator] prepareURLRequest:request error:error];
    
    NSString *startLog = [NSString stringWithFormat:@"\n\
**************************************************************\n\
*                       Request Start                        *\n\
**************************************************************\n\
API Info: <%@> URL:  [ %@ ]   < %@ %@ >\n\
Params:\n\
%@\n\
",
request.class,
urlRequest.URL.absoluteString,
request.serviceIdentifier,
urlRequest.HTTPMethod,
request.finalRequestParams ?: @"-"];
    [request.progressLog appendString:startLog];
    
    GSHTTPServiceCenter *center = [GSHTTPServiceCenter defaultCenter];
    GSNetService service = [center serviceWithIdentifier:[request serviceIdentifier]];
    if ([service respondsToSelector:@selector(extraDescForRequestHeaderFields:)]) {
        NSString *desc = [service extraDescForRequestHeaderFields:urlRequest.allHTTPHeaderFields];
        [request.progressLog appendString:desc];
    }
    
    if ([GSNetworkConfig sharedConfig].needRequstHeaderLog) {
        NSString *headers = [NSString stringWithFormat:@"\
Headers:\n\
%@\n\n", urlRequest.allHTTPHeaderFields];
        [request.progressLog appendString:headers];
    }
    
    NSString *sep = @"---------------------------   sep    -------------------------\n";
    [request.progressLog appendString:sep];
    
    switch ([request requestMethod]) {
        case GSRequestMethodGET:
            // download task
            if (request.resumableDownloadPath) {
                return [self gs_downloadTaskWithRequest:urlRequest
                                           downloadPath:request.resumableDownloadPath
                                               progress:request.resumableDownloadProgressBlock
                                                request:request];
            }
            
        default:
            // other tasks (including upload)
            return [self gs_dataTaskWithRequest:urlRequest request:request];
    }
}

- (NSURLSessionDataTask *)gs_dataTaskWithRequest:(NSURLRequest *)urlRequest request:(GSRootRequest *)request  {
    __block NSURLSessionDataTask *dataTask = nil;
    AFHTTPSessionManager *manager = [self managerForRequest:request];
    dataTask = [manager dataTaskWithRequest:urlRequest
                          completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *_error)
                {
                    [self handleRequestResult:dataTask responseObject:responseObject error:_error];
                }];
    
    return dataTask;
}


- (NSURLSessionDownloadTask *)gs_downloadTaskWithRequest:(NSURLRequest *)urlRequest
                                            downloadPath:(NSString *)downloadPath
                                                progress:(nullable void (^)(NSProgress *downloadProgress))progressBlock
                                                 request:(GSRootRequest *)request
{
    NSString *downloadTargetPath;
    BOOL isDirectory;
    if(![[NSFileManager defaultManager] fileExistsAtPath:downloadPath isDirectory:&isDirectory]) {
        isDirectory = NO;
    }
    // If targetPath is a directory, use the file name we got from the urlRequest.
    // Make sure downloadTargetPath is always a file, not directory.
    if (isDirectory) {
        NSString *fileName = [urlRequest.URL lastPathComponent];
        downloadTargetPath = [NSString pathWithComponents:@[downloadPath, fileName]];
    } else {
        downloadTargetPath = downloadPath;
    }
    
    // AFN use `moveItemAtURL` to move downloaded file to target path,
    // this method aborts the move attempt if a file already exist at the path.
    // So we remove the exist file before we start the download task.
    // https://github.com/AFNetworking/AFNetworking/issues/3775
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadTargetPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:downloadTargetPath error:nil];
    }
    
    NSString *path = [self incompleteDownloadTempPathForDownloadPath:downloadPath].path;
    BOOL resumeDataFileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    NSData *data = [NSData dataWithContentsOfURL:[self incompleteDownloadTempPathForDownloadPath:downloadPath]];
    BOOL resumeDataIsValid = [GSNetworkUtils validateResumeData:data];
    
    BOOL canBeResumed = resumeDataFileExists && resumeDataIsValid;
    BOOL resumeSucceeded = NO;
    
    __block NSURLSessionDownloadTask *downloadTask = nil;
    // Try to resume with resumeData.
    // Even though we try to validate the resumeData, this may still fail and raise excecption.
    AFHTTPSessionManager *manager = [self managerForRequest:request];
    if (canBeResumed) {
        @try {
            downloadTask = [manager downloadTaskWithResumeData:data
                                                      progress:progressBlock
                                                   destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath,
                                                                                 NSURLResponse * _Nonnull response)
                            {
                                return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
                            } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath,
                                                  NSError * _Nullable error) {
                                [self handleRequestResult:downloadTask responseObject:filePath error:error];
                            }];
            resumeSucceeded = YES;
        } @catch (NSException *exception) {
            GSNLog(@"Resume download failed, reason = %@", exception.reason);
            resumeSucceeded = NO;
        }
    }
    if (!resumeSucceeded) {
        downloadTask = [manager downloadTaskWithRequest:urlRequest
                                               progress:progressBlock
                                            destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath,
                                                                          NSURLResponse * _Nonnull response)
                        {
                            return [NSURL fileURLWithPath:downloadTargetPath isDirectory:NO];
                        }
                                      completionHandler:^(NSURLResponse * _Nonnull response,
                                                          NSURL * _Nullable filePath,
                                                          NSError * _Nullable error)
                        {
                            [self handleRequestResult:downloadTask responseObject:filePath error:error];
                        }];
    }
    
    return downloadTask;
}

#pragma mark - Resumable Download
- (NSString *)incompleteDownloadTempCacheFolder {
    NSFileManager *fileManager = [NSFileManager new];
    static NSString *cacheFolder;
    
    if (!cacheFolder) {
        NSString *cacheDir = NSTemporaryDirectory();
        cacheFolder = [cacheDir stringByAppendingPathComponent:kGSNetworkIncompleteDownloadFolderName];
    }
    
    NSError *error = nil;
    if(![fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
        GSNLog(@"Failed to create cache directory at %@", cacheFolder);
        cacheFolder = nil;
    }
    return cacheFolder;
}

- (NSURL *)incompleteDownloadTempPathForDownloadPath:(NSString *)downloadPath {
    NSString *tempPath = nil;
    NSString *md5URLString = [GSNetworkUtils md5StringFromString:downloadPath];
    tempPath = [[self incompleteDownloadTempCacheFolder] stringByAppendingPathComponent:md5URLString];
    return [NSURL fileURLWithPath:tempPath];
}

#pragma mark - Private methods
- (BOOL)validateResult:(GSRootRequest *)request error:(NSError * _Nullable __autoreleasing *)outError {
    // status code
    if (![request validateStatusCode]) {
        if (outError) *outError = [NSError errorWithDomain:GSRequestValidationErrorDomain
                                                      code:GSRequestValidationErrorInvalidStatusCode
                                                  userInfo:@{NSLocalizedDescriptionKey:@"Invalid status code"}];
        return NO;
    }
    
    // JSONObject
    id json = [request responseJSONObject];
    id validator = [request validatorForJSONObject];
    if (json && validator && ![GSNetworkUtils validateJSON:json withValidator:validator]) {
        if (outError)  *outError = [NSError errorWithDomain:GSRequestValidationErrorDomain
                                                       code:GSRequestValidationErrorInvalidJSONFormat
                                                   userInfo:@{NSLocalizedDescriptionKey:@"Invalid JSON format"}];
        return NO;
    }
    
    // service
    GSHTTPService <GSHTTPServiceProtocol> *service = [request service];
    NSError *serviceError = nil;
    if (![service validateResponseObject:request.responseObject request:request error:&serviceError]) {
        if (outError) {
            if (serviceError) {
                *outError = serviceError;
                return NO;
            }
            
            NSString *desc = nil;
            desc = [NSString stringWithFormat:@"Invalid response judged by <%@>", request.serviceIdentifier];
            *outError = [NSError errorWithDomain:GSRequestValidationErrorDomain
                                            code:GSRequestValidationErrorInvalidResponseObject
                                        userInfo:@{NSLocalizedDescriptionKey:desc}];
        }
        return NO;
    }
    
    // request
    NSError *requestError = nil;
    if (![request validateResponseObjectWithError:&requestError]) {
        if (outError) {
            if (requestError) {
                *outError = requestError;
                return NO;
            }
            
            NSString *desc = nil;
            desc = [NSString stringWithFormat:@"Invalid response judged by <%@>", NSStringFromClass([request class])];
            *outError = [NSError errorWithDomain:GSRequestValidationErrorDomain
                                            code:GSRequestValidationErrorInvalidResponseObject
                                        userInfo:@{NSLocalizedDescriptionKey:desc}];
        }
        return NO;
    }
    
    return YES;
}

- (AFHTTPSessionManager *)managerForRequest:(GSRootRequest *)request {
    // 由服务类型和 responseSerializerType 映射一个 manager，主要还是考虑到返回数据时有异步时差异处理
    NSAssert([request serviceIdentifier], @"ServiceIdentifier must not be nil");
    NSDictionary *keyDic = @{[request serviceIdentifier]:@([request responseSerializerType])};
    AFHTTPSessionManager *manager = self.sessionManagerCache[keyDic];
    if (!manager) {
        manager = [self createManagerForRequest:request];
        self.sessionManagerCache[keyDic] = manager;
    }
    
    return manager;
}

- (AFHTTPSessionManager *)createManagerForRequest:(GSRootRequest *)request {
    AFHTTPSessionManager *mananger = [[AFHTTPSessionManager alloc] init];
    // Take over the status code validation
    mananger.completionQueue = _processingQueue;
    switch ([request responseSerializerType]) {
        case GSResponseSerializerTypeJSON:
            mananger.responseSerializer = _jsonResponseSerializer;
            break;
            
        case GSResponseSerializerTypeXMLParser:
            mananger.responseSerializer = [AFXMLParserResponseSerializer serializer];
            break;
            
        default:
            mananger.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
    }
    
    mananger.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html",
                                                          @"text/plain",
                                                          @"application/json", nil];
    
    return mananger;
}

#pragma mark - protocol
- (void)gsJSONResponseSerializer:(GSJSONResponseSerializer *)serializer
                 didFailResponse:(NSHTTPURLResponse *)response
                            data:(NSData *)data {
    if ([GSNetworkConfig sharedConfig].debugLogEnabled) {
        for (GSRootRequest *request in _requestsRecord.allValues) {
            if (request.response != response) continue;
            
            NSString *possibleJSONString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
NSString *errorJSONString = [NSString stringWithFormat:@"\n🐤🐤🐤🐤🐤\n\
%@\n\
🐤🐤🐤🐤🐤", possibleJSONString ?: @"-"];
            [request.progressLog appendString:errorJSONString];
        }
    }
}

#pragma mark - Setters and getters
- (NSMutableDictionary *)sessionManagerCache {
    if (!_sessionManagerCache) {
        _sessionManagerCache = [[NSMutableDictionary alloc] init];
    }
    
    return _sessionManagerCache;
}

@end
