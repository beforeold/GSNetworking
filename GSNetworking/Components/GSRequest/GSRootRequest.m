//
//  RootRequest.m
//
//  Copyright (c)  BRBR Co.ltd

#import "GSRootRequest.h"
#import "GSRequestProxy.h"
#import "GSNetworkPrivate.h"
#import "GSHTTPServiceCenter.h"


#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

NSString *const GSRequestValidationErrorDomain = @"com.BRBR.request.validation";

@interface GSRootRequest ()

@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;

@property (nonatomic, strong, readwrite) NSData *responseData;
@property (nonatomic, strong, readwrite) id responseJSONObject;
@property (nonatomic, strong, readwrite) id responseObject;
@property (nonatomic, strong, readwrite) NSString *responseString;

@property (nonatomic, strong, readwrite) NSError *error;

@end

@implementation GSRootRequest
#pragma mark - Lifecycle
- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>{ URL: %@ } { method: %@ } { params: %@ }",
            NSStringFromClass([self class]),
            self,
            self.currentRequest.URL,
            self.currentRequest.HTTPMethod,
            [self requestParams]];
}

- (instancetype)init {
    self = [super init];
    if (self) {
#ifdef DEBUG
        _progressLog = [[NSMutableString alloc] init];
#endif
    }
    
    return self;
}

#pragma mark - Request and Response Information
- (NSHTTPURLResponse *)response {
    return (NSHTTPURLResponse *)self.requestTask.response;
}

- (NSInteger)responseStatusCode {
    return [self response].statusCode;
}

- (NSDictionary *)responseHeaders {
    return [self response].allHeaderFields;
}

- (NSURLRequest *)currentRequest {
    return [self requestTask].currentRequest;
}

- (NSURLRequest *)originalRequest {
    return [self requestTask].originalRequest;
}

- (BOOL)isCancelled {
    if (![self requestTask]) {
        return NO;
    }
    return [self requestTask].state == NSURLSessionTaskStateCanceling;
}

- (BOOL)isExecuting {
    if (![self requestTask]) {
        return NO;
    }
    return [self requestTask].state == NSURLSessionTaskStateRunning;
}

#pragma mark - Request Configuration

- (void)setCompletionBlockWithSuccess:(GSRequestSuccessBlock)success
                              failure:(GSRequestCompletionBlock)failure {
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
    /// 同时清除 accessoryies
    self.requestAccessories = nil;
}

- (void)addAccessory:(id<GSRequestAccessory>)accessory {
    if (!accessory) return;
    [self.requestAccessories addObject:accessory];
}

#pragma mark - Request Action
- (void)start {
    [self toggleAccessoriesWillStartCallBack];
    [[GSRequestProxy sharedProxy] addRequest:self];
}

- (void)cancel {
    [self toggleAccessoriesWillStopCallBack];
    self.delegate = nil;
    [[GSRequestProxy sharedProxy] cancelRequest:self];
    [self toggleAccessoriesDidStopCallBack];
}

- (void)startWithSuccess:(GSRequestSuccessBlock)success
                 failure:(GSRequestCompletionBlock)failure {
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}

- (void)startWithSuccess:(GSRequestSuccessBlock)success {
    [self startWithSuccess:success failure:nil];
}

#pragma mark - Subclass Override
- (NSString *)serviceIdentifier {
    return @"GSDefaultService";
}

- (NSString *)requestURL {
    return nil;
}

- (id)requestParams {
    return nil;
}

- (NSString *)baseURL {
    return self.service.apiBaseUrl;
}

- (void)requestCompletePreprocessor {
}

- (void)requestCompleteFilter {
}

- (void)requestFailedPreprocessor {
}

- (void)requestFailedFilter {
}

- (id)cacheFileNameFilterForRequestParams:(id)params {
    return params;
}

- (GSRequestMethod)requestMethod {
    return self.service.child.defaultMethod;
}

- (GSRequestSerializerType)requestSerializerType {
    return self.service.child.defaultReqSerialType;
}

- (GSResponseSerializerType)responseSerializerType {
    return self.service.child.defaultRespSerialType;
}

- (NSArray *)requestAuthorizationHeaderFieldArray {
    return nil;
}

- (NSDictionary *)requestHeaderFields {
    return nil;
}

- (BOOL)useCDN {
    return NO;
}

- (NSString *)cdnURL {
    return nil;
}

- (BOOL)allowsCellularAccess {
    return YES;
}

#pragma mark Validator
- (id)validatorForJSONObject {
    return nil;
}

- (BOOL)validateStatusCode {
    NSInteger statusCode = [self responseStatusCode];
    return [self.service.child validateStatusCode:statusCode];
}

- (BOOL)validateResponseObjectWithError:(NSError **)error {
    return YES;
}

#pragma mark - Private
- (GSHTTPService <GSHTTPServiceProtocol> *)service {
    NSString *identifier = [self serviceIdentifier];
    GSHTTPService <GSHTTPServiceProtocol> *service = [[GSHTTPServiceCenter defaultCenter] serviceWithIdentifier:identifier];
    return service;
}

#pragma mark - Setters and getters
- (NSMutableArray<id<GSRequestAccessory>> *)requestAccessories {
    if (!_requestAccessories) {
        _requestAccessories = [[NSMutableArray alloc] init];
    }
    
    return _requestAccessories;
}

@end
