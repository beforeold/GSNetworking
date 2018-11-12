//
//  NSError+ErrorMessage.h
//  GSNetworking
//
//  Created by Donnie on 16/3/21.
//  Copyright © 2016年 BRBR co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  请求返回的状态码类型
 */
typedef NS_ENUM(NSInteger, GSResponseStatusCode) {
    GSResponseStatusCodeBadParams = -1,                 // 参数异常
    GSResponseStatusCodeSuccess = 0,                    // 业务成功通过
    GSResponseStatusCodeNotLogined = 440,               // 未登录，token无效
    GSResponseStatusCodeServerException = 500,          // 服务器内部异常
    GSResponseStatusCodeServerError = 3840,             // 服务端异常或者参数异常
    GSResponseStatusCodeTimeout = -1001,                // 网络超时
    GSResponseStatusCodeDataTimeOut = 40001,            // 传入数据过时刷新此原有数据
    
    GSResponseStatusCodeUnsupportMethodType = 10020,    // 不支持的请求方法类型, put, delete....
    
    GSResponseStatusCodeParsingError = 20020,           // 数据模型转换解析失败
    GSResponseStatusCodeNullOrNilData = 20021,          // 返回data是null或者nil
    GSResponseStatusCodeUnexpectedDataType = 20022,     // 非期望的数据类型 不是期望的字典或者数组
};


@interface NSError (HTTPErrorMessage)

/**
 *  获取错误的提示语(展示给用户)
 */
@property (nonatomic, readonly) NSString *httpMsg;

#pragma mark - 构造方法

/// 构造方法, 获取一个model解析错误
+ (instancetype)http_parsingErrorWithResponse:(id)response;

/// 构造方法，获取一个model解析时data为null/nil的错误
+ (instancetype)http_nullOrNilDataErrorWithResponse:(id)response;

/// 构造方法，获取一个model解析时data为null/nil的错误
+ (instancetype)http_unexpectedDataTypeErrorWithResponse:(id)response;

/// 构造方法，方便传入message
+ (instancetype)http_errorWithDomain:(NSString *)domain code:(NSInteger)code message:(NSString *)message;


#pragma mark - 工具方法
/**
 *  错误信息的内部描述，不展示给用户
 *
 *  @param code 错误code
 *
 *  @return 错误的内部描述
 */
+ (NSString *)http_descriptionForErrorCode:(NSInteger)code;

#pragma mark - 常量
/**
 *  返回信息中erroMsg的key
 */
extern NSString *const kGSHTTPErrorMsg;

@end
