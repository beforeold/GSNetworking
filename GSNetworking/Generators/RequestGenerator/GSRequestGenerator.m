//
//  AXRequestGenerator.m
//  RTNetworking
//
//  Created by Brook on 2017/3/8.
//  Copyright © 2017年 BRBR Co ltd. All rights reserved.
//

//#import "GSSignatureGenerator.h"
#import "GSHTTPServiceCenter.h"
//#import "GSCommonParamsGenerator.h"
#import "NSDictionary+AXNetworkingMethods.h"
#import "GSNetworkingConfiguration.h"
#import "NSObject+AXNetworkingMethods.h"
#import "GSHTTPService.h"
#import "NSObject+AXNetworkingMethods.h"
//#import "GSNetworkLogger.h"
#import "NSURLRequest+CTNetworkingMethods.h"

#import "GSRequestGenerator.h"
#import <AFNetworking/AFNetworking.h>
#import "GSRootRequest.h"
#import "GSNetworkConfig.h"


static NSString *const kGSRequestMethodGET = @"GET";
static NSString *const kGSRequestMethodPOST = @"POST";
static NSString *const kGSRequestMethodHEAD = @"HEAD";
static NSString *const kGSRequestMethodPUT = @"PUT";
static NSString *const kGSRequestMethodDELETE = @"DELETE";
static NSString *const kGSRequestMethodPATCH = @"PATCH";


@interface GSRequestGenerator ()
{
    GSNetworkConfig *_config;
}
@property (nonatomic, strong) AFHTTPRequestSerializer *httpRequestSerializer;

@end

@implementation GSRequestGenerator
#pragma mark - public methods
+ (instancetype)sharedGenerator
{
    static dispatch_once_t onceToken;
    static GSRequestGenerator *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[GSRequestGenerator alloc] init];
    });
    return sharedInstance;
}

- (NSURLRequest *)prepareURLRequest:(GSRootRequest *)baseRequest error:(NSError * __autoreleasing *)error {
    GSHTTPServiceCenter *center = [GSHTTPServiceCenter defaultCenter];
    GSNetService service = [center serviceWithIdentifier:[baseRequest serviceIdentifier]];
    // 1、URL
    NSString *URLString = [self prepareURLForRequest:baseRequest service:service];
    if ([service respondsToSelector:@selector(reformURL:)]) {
        URLString = [service reformURL:URLString];
    }
    
    // 2、params
    id parameters = [baseRequest requestParams];
    
    // 处理每个接口都有的参数
    if ([service respondsToSelector:@selector(defaultParams)] && [parameters isKindOfClass:[NSDictionary class]]) {
        NSDictionary *defaultParams = [service defaultParams];
        parameters = [parameters mutableCopy];
        [parameters addEntriesFromDictionary:defaultParams];
    }
    
    // 对参数进行最后的处理
    if ([service respondsToSelector:@selector(reformParameterFinally:)]) {
        parameters = [service reformParameterFinally:parameters];
    }
    
    /// 调用 KVC 对 readonly 属性赋值
    [baseRequest setValue:parameters forKey:NSStringFromSelector(@selector(finalRequestParams))];
    
    // 3、HeadFields and so on
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForRequest:baseRequest
                                                                       finalURLStr:URLString
                                                                           service:service];
    
    NSString *method = nil;
    switch ([baseRequest requestMethod]) {
        case GSRequestMethodGET:
            method = kGSRequestMethodGET;
            break;
            
        case GSRequestMethodPOST: {
            method = kGSRequestMethodPOST;
            AFConstructingBlock block = baseRequest.constructingBodyBlock;
            if (!block) break;
            // else means -> upload file
            return [requestSerializer multipartFormRequestWithMethod:method
                                                           URLString:URLString
                                                          parameters:parameters
                                           constructingBodyWithBlock:block
                                                               error:error];
        }
            
        case GSRequestMethodHEAD:
            method = kGSRequestMethodHEAD;
            break;
            
        case GSRequestMethodPUT:
            method = kGSRequestMethodPOST;
            break;

        case GSRequestMethodDELETE:
            method = kGSRequestMethodDELETE;
            break;
            
        case GSRequestMethodPATCH:
            method = kGSRequestMethodPATCH;
            break;
    }
    
    return [requestSerializer requestWithMethod:method
                                      URLString:URLString
                                     parameters:parameters
                                          error:error];
}

#pragma mark - private methods
/// 拼接 URL 字符串
- (NSString *)prepareURLForRequest:(GSRootRequest *)request service:(GSNetService)service {
    NSParameterAssert(request != nil);
    
    NSString *detailUrl = [request requestURL];
    NSURL *temp = [NSURL URLWithString:detailUrl];
    // If detailUrl is valid URL
    if (temp && temp.host && temp.scheme) {
        return detailUrl;
    }
    // Filter URL if needed
    NSArray *filters = [_config urlFilters];
    for (id<GSURLFilterProtocol> f in filters) {
        detailUrl = [f filterUrl:detailUrl withRequest:request];
    }
    
    if ([detailUrl hasPrefix:@"/"]) {
        detailUrl = [detailUrl substringFromIndex:1];
    }
    
    NSString *baseUrl;
    if ([request useCDN]) {
        if ([request cdnURL].length) {
            baseUrl = [request cdnURL];
        } else {
            baseUrl = [_config cdnURL];
        }
    } else {
        NSString *requstURL = [request baseURL];
        if (requstURL.length) {
            baseUrl = requstURL;
        } else {
            baseUrl = [_config baseURL];
        }
        
        NSString *apiVersion = service.apiVersion;
        if (apiVersion.length) {
            baseUrl = [baseUrl stringByAppendingFormat:@"/%@", apiVersion];
        }
    }
    // URL slash compability
    NSURL *url = [NSURL URLWithString:baseUrl];
    
    if (baseUrl.length > 0 && ![baseUrl hasSuffix:@"/"]) {
        url = [url URLByAppendingPathComponent:@""];
    }
    
    return [NSURL URLWithString:detailUrl relativeToURL:url].absoluteString;
}

/// a requestSerializer each request
/// 配置请求序列化器，注意是每一个请求配置一个独立的 requestSerializer， 不复用
- (AFHTTPRequestSerializer *)requestSerializerForRequest:(GSRootRequest *)request
                                             finalURLStr:(NSString *)finalURLStr
                                                 service:(GSHTTPService <GSHTTPServiceProtocol> *)service
{
    AFHTTPRequestSerializer *requestSerializer = nil;
    if (request.requestSerializerType == GSRequestSerializerTypeHTTP) {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    } else if (request.requestSerializerType == GSRequestSerializerTypeJSON) {
        requestSerializer = [AFJSONRequestSerializer serializer];
    }
    
    NSTimeInterval interval = [request requestTimeoutInterval];
    /// 请求的超时处理
    if (interval == 0) {
        if ([service respondsToSelector:@selector(defaultTimeoutInterval)]) {
            interval = [service defaultTimeoutInterval];
        } else {
            interval = kGSNetworkingTimeoutSeconds;
        }
    }
    
    requestSerializer.timeoutInterval = interval;
    requestSerializer.allowsCellularAccess = [request allowsCellularAccess];
    
    // If api needs server username and password
    NSArray<NSString *> *authorization = [request requestAuthorizationHeaderFieldArray];
    if (authorization) {
        [requestSerializer setAuthorizationHeaderFieldWithUsername:authorization.firstObject
                                                          password:authorization.lastObject];
    }
    
    // 配置请求头信息
    NSMutableDictionary *finalFields = [NSMutableDictionary dictionary];
    // 1 默认统一请求头
    if ([service respondsToSelector:@selector(defaultHeaderFields)]) {
        NSDictionary *fields = [service defaultHeaderFields];
        [finalFields addEntriesFromDictionary:fields];
    }
    
    // 2 默认为 URL 配置的请求头
    if ([service respondsToSelector:@selector(headerFieldsForEachURL:)]) {
        NSDictionary *fields = [service headerFieldsForEachURL:finalURLStr];
        [finalFields addEntriesFromDictionary:fields];
    }
    
    // 3 特定 Request 定制的请求头
    // If api needs to add custom value to HTTPHeaderField
    NSDictionary<NSString *, NSString *> *fields = [request requestHeaderFields];
    [finalFields addEntriesFromDictionary:fields];
    
    [finalFields enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [requestSerializer setValue:obj forHTTPHeaderField:key];
    }];
    
    return requestSerializer;
}

@end
