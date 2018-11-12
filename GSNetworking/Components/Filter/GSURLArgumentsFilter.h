//
// Created by BRBR on 8/27/14.
// Copyright (c) 2014 BRBR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GSNetworkConfig.h"
#import "GSRootRequest.h"

/// 给url追加arguments，用于全局参数，比如AppVersion, ApiVersion等
@interface GSURLArgumentsFilter : NSObject <GSURLFilterProtocol>

+ (GSURLArgumentsFilter *)filterWithArguments:(NSDictionary *)arguments;

- (NSString *)filterUrl:(NSString *)originUrl withRequest:(GSRootRequest *)request;

@end
