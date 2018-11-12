//
//  NetworkPrivate.h
//
//  Copyright (c)  BRBR Co.ltd 

#import <Foundation/Foundation.h>
#import "GSRequest.h"
#import "GSRootRequest.h"
#import "GSBatchRequest.h"
#import "GSChainRequest.h"
#import "GSRequestProxy.h"
#import "GSNetworkConfig.h"
#import "GSHTTPService.h"
#import "GSNetworkingConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT void GSNLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);

@class AFHTTPSessionManager;

@interface GSNetworkUtils : NSObject

+ (BOOL)validateJSON:(id)json withValidator:(id)jsonValidator;
+ (void)addDoNotBackupAttribute:(NSString *)path;
+ (NSString *)md5StringFromString:(NSString *)string;
+ (NSString *)appVersionString;
+ (NSStringEncoding)stringEncodingWithRequest:(GSRootRequest *)request;
+ (BOOL)validateResumeData:(NSData *)data;

@end

@interface GSRequest (Getter)

- (NSString *)cacheBasePath;

@end


@interface GSRootRequest (Getter)

@property (nonatomic, readonly) GSHTTPService <GSHTTPServiceProtocol> *service;

@end

@interface GSRootRequest (Setter)

@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readwrite, nullable) NSData *responseData;
@property (nonatomic, strong, readwrite, nullable) id responseJSONObject;
@property (nonatomic, strong, readwrite, nullable) id responseObject;
@property (nonatomic, strong, readwrite, nullable) NSString *responseString;
@property (nonatomic, strong, readwrite, nullable) NSError *error;

@end

// !!Todo 'toggle' means YES or NO, bad usage. try 'switch'
@interface GSRootRequest (RequestAccessory)

- (void)toggleAccessoriesWillStartCallBack;
- (void)toggleAccessoriesWillStopCallBack;
- (void)toggleAccessoriesDidStopCallBack;

@end

@interface GSBatchRequest (RequestAccessory)

- (void)toggleAccessoriesWillStartCallBack;
- (void)toggleAccessoriesWillStopCallBack;
- (void)toggleAccessoriesDidStopCallBack;

@end

@interface GSChainRequest (RequestAccessory)

- (void)toggleAccessoriesWillStartCallBack;
- (void)toggleAccessoriesWillStopCallBack;
- (void)toggleAccessoriesDidStopCallBack;

@end

@interface GSRequestProxy (Private)

- (AFHTTPSessionManager *)manager;
- (void)resetURLSessionManager;
- (void)resetURLSessionManagerWithConfiguration:(NSURLSessionConfiguration *)configuration;

- (NSString *)incompleteDownloadTempCacheFolder;

@end

NS_ASSUME_NONNULL_END

