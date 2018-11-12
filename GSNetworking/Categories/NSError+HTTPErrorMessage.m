 //
//  NSError+ErrorMessage.m
//  GSNetworking
//
//  Created by Donnie on 16/3/21.
//  Copyright © 2016年 BRBR co.,Ltd. All rights reserved.
//

#import "NSError+HTTPErrorMessage.h"


NSString *const kGSHTTPErrorMsg = @"kGSHTTPErrorMsg";

/// 最长的合理msg长度，否则显示 网络不可用，请稍后重试
static NSInteger const kMaxRightMsgLength = 20;

/*
 
 PS： 20161017 产品要求网络相关错误统一显示为 网络不可用，请稍后重试
 
 */

/// 网络解析错误
static NSString *const kGSParsingErrorMsg = @"网络不可用，请稍后重试";

/// 网络请求错误
static NSString *const kGSReuqestErrorMsg = @"网络不可用，请稍后重试";

/// 别处登录
static NSString *const kGSNotLoginErrorMsg = @"您的账号已在别处登录";

/// 无法连接网络，请检查
static NSString *const kGSNoNetErrorMsg = @"网络不可用，请稍后重试";

/// 无法连接到服务器
static NSString *const kGSNoServerErrorMsg = @"网络不可用，请稍后重试";

/// 超时错误
static NSString *const kGSTimeoutErrorMsg = @"网络不可用，请稍后重试";

/// 其他错误
static NSString *const kGSOtherNetErrorMsg = @"网络不可用，请稍后重试";

@implementation NSError (HTTPErrorMessage)

+ (instancetype)http_parsingErrorWithResponse:(id)response {
    NSString *message = kGSParsingErrorMsg;
    NSError *error = [self http_errorWithDomain:@"数据解析出错" code:GSResponseStatusCodeParsingError message:message];
    
    return error;
}

+ (instancetype)http_nullOrNilDataErrorWithResponse:(id)response {
    NSString *message = kGSParsingErrorMsg;
    NSError *error = [self http_errorWithDomain:@"数据为nil或者null" code:GSResponseStatusCodeNullOrNilData message:message];
    
    return error;
}

+ (instancetype)http_unexpectedDataTypeErrorWithResponse:(id)response {
    NSString *message = kGSParsingErrorMsg;
    NSError *error = [self http_errorWithDomain:@"数据不是期望的类型" code:GSResponseStatusCodeUnexpectedDataType message:message];
    
    return error;
}

- (NSString *)httpMsg {
    return self.userInfo[kGSHTTPErrorMsg];
}

#pragma mark - 构造方法
/**
 *  构造方法，请求成功的回调错误信息
 *
 *  @param requestObject 回调的错误信息
 */
+ (instancetype)http_errorFromResponseObject:(id)requestObject {
    if ([requestObject isMemberOfClass:[NSDictionary class]]) {
        
        id msg = requestObject[@"msg"];
        return [self http_errorWithDomain:@"ResponsObjectDomain"
                                code:[requestObject[@"code"] integerValue]
                             message:msg];
        
    }
    
    return nil;
}

/**
 *  NSError的构造方法
 *
 *  @param domain  domain
 *  @param code    错误code
 *  @param message 错误的描述
 *
 *  @return NSError实例
 */
+ (instancetype)http_errorWithDomain:(NSString *)domain code:(NSInteger)code message:(NSString *)message {
    if ([message isKindOfClass:[NSNull class]]) {
        message = kGSParsingErrorMsg;
    }
    
    message = [self http_messageForErrorCode:code message:message];
    domain = domain ?: @"";
    
    return [NSError errorWithDomain:domain code:code userInfo:@{kGSHTTPErrorMsg:message}];
}

#pragma mark - 工具方法

/**
 *  错误信息的外部描述，展示给用户
 *
 *  @param code 错误code
 *
 *  @return 给用户展示的错误信息
 */
+ (NSString *)http_messageForErrorCode:(NSInteger)code message:(NSString *)message {
    if (NSURLErrorTimedOut == code) {
        // 超时
        return kGSTimeoutErrorMsg;
        
    }else if (NSURLErrorNotConnectedToInternet == code) {
        // 断网
        return kGSNoNetErrorMsg;
    }
    
    else if (GSResponseStatusCodeBadParams == code) {
        // 请求参数异常
        return message.length ? (message.length < kMaxRightMsgLength ? message : kGSReuqestErrorMsg) : kGSReuqestErrorMsg;
        
    }else if (GSResponseStatusCodeNotLogined == code) {
        // 登录token过期
        return kGSNotLoginErrorMsg;
    
    }else if (NSURLErrorCannotFindHost == code || NSURLErrorCannotConnectToHost == code) {
        return kGSNoServerErrorMsg;
    }
    
    // 其他情况
    return message.length ? message : kGSOtherNetErrorMsg;
}

/**
 *  错误信息的内部描述，不展示给用户
 *
 *  @param code 错误code
 *
 *  @return 错误的内部描述
 */
+ (NSString *)http_descriptionForErrorCode:(NSInteger)code {
    switch (code) {
        case 400: return @"网络错误400";
        case 404: return @"网络错误404";
        case 3840: return @"参数格式不符 或者 URL不匹配";
        case 500: return @"服务器内部异常";
            
        case NSURLErrorUnknown: return @"未知错误（业务参数校验失败）";
        case NSURLErrorCancelled:   return @"请求取消";
        case NSURLErrorBadURL: return @"URL异常";
        case NSURLErrorTimedOut: return @"请求超时";
        case NSURLErrorUnsupportedURL: return @"不支持的URL";
        case NSURLErrorCannotFindHost: return @"无法找到主机";
        case NSURLErrorCannotConnectToHost: return @"无法连接到主机";
        case NSURLErrorNetworkConnectionLost: return @"网络连接丢失";
        case NSURLErrorDNSLookupFailed: return @"DNS查找失败";
        case NSURLErrorHTTPTooManyRedirects: return @"HTTP重定向过多";
        case NSURLErrorResourceUnavailable: return @"资源不可使用";
        case NSURLErrorNotConnectedToInternet: return @"因特网无法连接";
        case NSURLErrorRedirectToNonExistentLocation: return @"重定向至不存在的位置";
        case NSURLErrorBadServerResponse: return @"服务器响应异常";
        case NSURLErrorUserCancelledAuthentication: return @"用户取消验证";
        case NSURLErrorUserAuthenticationRequired: return @"需要用户验证";
        case NSURLErrorZeroByteResource: return @"零字节资源";
        case NSURLErrorCannotDecodeRawData: return @"无法解码原数据rawData";
        case NSURLErrorCannotDecodeContentData: return @"无法解码内容数据contentData";
        case NSURLErrorCannotParseResponse: return @"无法解析响应";
        case NSURLErrorFileDoesNotExist: return @"文件不存在";
        case NSURLErrorFileIsDirectory: return @"文件是路径";
        case NSURLErrorNoPermissionsToReadFile: return @"未授权读取文件";
        case NSURLErrorDataLengthExceedsMaximum: return @"数据长度超出最大值";
            
            // SSL errors
        case NSURLErrorSecureConnectionFailed: return @"安全连接失败";
        case NSURLErrorServerCertificateHasBadDate: return @"服务器证书日期异常";
        case NSURLErrorServerCertificateUntrusted: return @"服务器证书不可信";
        case NSURLErrorServerCertificateHasUnknownRoot: return @"服务器证书root未知";
        case NSURLErrorServerCertificateNotYetValid: return @"服务器证书未生效";
        case NSURLErrorClientCertificateRejected: return @"客户证书拒绝";
        case NSURLErrorClientCertificateRequired: return @"需要客户证书";
        case NSURLErrorCannotLoadFromNetwork: return @"无法从网络加载";
            
            // Download and file I/O errors
        case NSURLErrorCannotCreateFile: return @"无法创建文件";
        case NSURLErrorCannotOpenFile: return @"无法打开文件";
        case NSURLErrorCannotCloseFile: return @"无法关闭文件";
        case NSURLErrorCannotWriteToFile: return @"无法写入到文件";
        case NSURLErrorCannotRemoveFile: return @"无法删除文件";
        case NSURLErrorCannotMoveFile: return @"无法移动文件";
        case NSURLErrorDownloadDecodingFailedMidStream: return @"下载解码失败MidStream";
        case NSURLErrorDownloadDecodingFailedToComplete: return @"下载解码失败ToComplete";
            
        case NSURLErrorInternationalRoamingOff: return @"NSURLErrorInternationalRoamingOff";
        case NSURLErrorCallIsActive: return @"NSURLErrorCallIsActive";
        case NSURLErrorDataNotAllowed: return @"NSURLErrorDataNotAllowed";
        case NSURLErrorRequestBodyStreamExhausted: return @"NSURLErrorRequestBodyStreamExhausted";
            
        case -1022: return @"网络安全要求https";                                      // NSURLErrorAppTransportSecurityRequiresSecureConnection  //必须iOS9
        case -995: return @"NSURLErrorBackgroundSessionRequiresSharedContainer";    // NSURLErrorBackgroundSessionRequiresSharedContainer，    // 必须iOS8
        case -996: return @"NSURLErrorBackgroundSessionInUseByAnotherProcess";      // NSURLErrorBackgroundSessionInUseByAnotherProcess        // 必须iOS8
        case -997: return @"NSURLErrorBackgroundSessionWasDisconnected";            // NSURLErrorBackgroundSessionWasDisconnected              // 必须iOS8
            
        default:
            return @"";
    }
}

@end
