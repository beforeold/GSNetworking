//
//  NSURLRequest+CTNetworkingMethods.m
//  RTNetworking
//
//  Created by BRBR on 14-5-26.
//  Copyright (c) 2014年 BRBR. All rights reserved.
//

#import "NSURLRequest+CTNetworkingMethods.h"
#import <objc/runtime.h>

static void *CTNetworkingRequestParams;

@implementation NSURLRequest (CTNetworkingMethods)

- (void)setRequestParams:(NSDictionary *)requestParams
{
    objc_setAssociatedObject(self, &CTNetworkingRequestParams, requestParams, OBJC_ASSOCIATION_COPY);
}

- (NSDictionary *)requestParams
{
    return objc_getAssociatedObject(self, &CTNetworkingRequestParams);
}

@end
