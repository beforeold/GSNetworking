//
//  AXService.h
//  RTNetworking
//
//  Created by Brook on 2017/3/8.
//  Copyright © 2017年 BRBR Co ltd. All rights reserved.
//  定义HTTP请求的相关服务配置，必须子类化使用，且子类必须遵循协议GSHTTPServiceProtocol

#import <Foundation/Foundation.h>
#import "GSNetworkingConfiguration.h"
#import "GSNetworkEnum.h"

@class GSHTTPService;
@protocol GSHTTPServiceProtocol;
typedef GSHTTPService <GSHTTPServiceProtocol> * GSNetService;

@class GSRootRequest;
// 所有GSHTTPService的派生类都要符合这个protocol
@protocol GSHTTPServiceProtocol <NSObject>

@property (nonatomic, readonly) BOOL isOnline;

@property (nonatomic, readonly) NSString *offlineApiBaseUrl;
@property (nonatomic, readonly) NSString *onlineApiBaseUrl;

@property (nonatomic, readonly) NSString *offlineApiVersion;
@property (nonatomic, readonly) NSString *onlineApiVersion;

@property (nonatomic, readonly) NSString *onlinePublicKey;
@property (nonatomic, readonly) NSString *offlinePublicKey;

@property (nonatomic, readonly) NSString *onlinePrivateKey;
@property (nonatomic, readonly) NSString *offlinePrivateKey;

/// 默认的请求方法
@property (nonatomic, assign, readonly) GSRequestMethod defaultMethod;
/// 默认的请求数据解析类型
@property (nonatomic, assign, readonly) GSRequestSerializerType defaultReqSerialType;
/// 默认的数据解析类型
@property (nonatomic, assign, readonly) GSResponseSerializerType defaultRespSerialType;
/// 对 状态码 进行校验
- (BOOL)validateStatusCode:(NSInteger)statusCode;
/// 对 返回结果 进行统一校验
- (BOOL)validateResponseObject:(id)responseObject request:(GSRootRequest *)request error:(NSError **)error;

@optional
/// 将 model 转为 JSONObject
- (id)modelToJSONObject:(id)model;
/// 将返回的 JSONObject 转成 model
- (id)modelWithResponseObject:(id)responseObject
                        class:(Class)clz
           expectedResultType:(GSExpectedResultType)type
                        error:(NSError **)error;
/// 对请求的 URL 进行改造
- (NSString *)reformURL:(NSString *)urlString;

/// 每个请求统一的请求参数
@property (nonatomic, readonly) NSDictionary *defaultParams;
/// 对请求参数进行最后的统一处理
- (id)reformParameterFinally:(id)parameters;

/// 默认统一的请求头信息
@property (nonatomic, copy, readonly) NSDictionary <NSString *, NSString *> *defaultHeaderFields;
/// 统一处理 URL 与请求头的关系
- (NSDictionary *)headerFieldsForEachURL:(NSString *)url;

/// 针对请求头的额外描述，只参与log，不参与业务
- (NSString *)extraDescForRequestHeaderFields:(NSDictionary <NSString *, NSString *> *)headerFields;

/// 默认超时时间
@property (nonatomic, readonly) NSTimeInterval defaultTimeoutInterval;

@end

@interface GSHTTPService : NSObject

@property (nonatomic, strong, readonly) NSString *publicKey;
@property (nonatomic, strong, readonly) NSString *privateKey;
@property (nonatomic, strong, readonly) NSString *apiBaseUrl;
@property (nonatomic, strong, readonly) NSString *apiVersion;

@property (nonatomic, weak) id<GSHTTPServiceProtocol> child;

@end
