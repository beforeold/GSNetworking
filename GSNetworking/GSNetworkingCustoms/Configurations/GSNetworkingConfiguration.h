//
//  GSNetworkingConfiguation.h
//  CTNetworking
//
//  Created by Brook on 2017/3/8.
//  Copyright © 2017年 BRBR Co ltd. All rights reserved.
//

#ifndef GSNetworkingConfiguration_h
#define GSNetworkingConfiguration_h

typedef NS_ENUM(NSInteger, CTAppType) {
    CTAppTypexxx
};

typedef NS_ENUM(NSUInteger, GSURLResponseStatus)
{
    GSURLResponseStatusSuccess, //作为底层，请求是否成功只考虑是否成功收到服务器反馈。至于签名是否正确，返回的数据是否完整，由上层的GSBaseAPIManager来决定。
    GSURLResponseStatusErrorTimeout,
    GSURLResponseStatusErrorNoNetwork // 默认除了超时以外的错误都是无网络错误。
};

static NSString *CTKeychainServiceName = @"xxxxx";
static NSString *CTUDIDName = @"xxxx";
static NSString *CTPasteboardType = @"xxxx";

static BOOL kCTShouldCache = NO;
static NSString *const kDefaultService = @"kDefaultService";
static BOOL kCTServiceIsOnline = NO;
static NSTimeInterval kGSNetworkingTimeoutSeconds = 15.0f;
static NSTimeInterval kGSCacheOutdateTimeSeconds = 300; // 5分钟的cache过期时间
static NSUInteger kGSCacheCountLimit = 1000; // 最多1000条cache

#endif /* GSNetworkingConfiguration_h */
