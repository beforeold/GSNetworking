//
//  AXService.m
//  RTNetworking
//
//  Created by Brook on 2017/3/8.
//  Copyright © 2017年 BRBR Co ltd. All rights reserved.
//

#import "GSHTTPService.h"
#import "NSObject+AXNetworkingMethods.h"

@implementation GSHTTPService

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSAssert([self conformsToProtocol:@protocol(GSHTTPServiceProtocol)], @"子类必须响应 GSHTTPServiceProtocol");
        self.child = (id<GSHTTPServiceProtocol>)self;
    }
    return self;
}

#pragma mark - getters and setters
- (NSString *)privateKey
{
    return self.child.isOnline ? self.child.onlinePrivateKey : self.child.offlinePrivateKey;
}

- (NSString *)publicKey
{
    return self.child.isOnline ? self.child.onlinePublicKey : self.child.offlinePublicKey;
}

- (NSString *)apiBaseUrl
{
    return self.child.isOnline ? self.child.onlineApiBaseUrl : self.child.offlineApiBaseUrl;
}

- (NSString *)apiVersion
{
    return self.child.isOnline ? self.child.onlineApiVersion : self.child.offlineApiVersion;
}

@end
