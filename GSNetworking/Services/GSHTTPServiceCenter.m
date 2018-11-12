//
//  AXServiceFactory.m
//  RTNetworking
//
//  Created by Brook on 2017/3/8.
//  Copyright © 2017年 BRBR Co ltd. All rights reserved.
//

#import "GSHTTPServiceCenter.h"

@interface GSHTTPServiceCenter ()

@property (nonatomic, strong) NSMutableDictionary *serviceStorage;

@end

@implementation GSHTTPServiceCenter

#pragma mark - getters and setters
- (NSMutableDictionary *)serviceStorage
{
    if (_serviceStorage == nil) {
        _serviceStorage = [[NSMutableDictionary alloc] init];
    }
    return _serviceStorage;
}

#pragma mark - life cycle
+ (instancetype)defaultCenter
{
    static dispatch_once_t onceToken;
    static GSHTTPServiceCenter *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[GSHTTPServiceCenter alloc] init];
    });
    return sharedInstance;
}

#pragma mark - public methods
- (GSNetService)serviceWithIdentifier:(NSString *)identifier
{
    if (self.serviceStorage[identifier] == nil) {
        self.serviceStorage[identifier] = [self newServiceWithIdentifier:identifier];
    }
    return self.serviceStorage[identifier];
}

#pragma mark - private methods
- (GSNetService)newServiceWithIdentifier:(NSString *)identifier
{
    Class clz = NSClassFromString(identifier);
    NSAssert(clz, @"identifier should be equeal to the class name");
    
    return [[clz alloc] init];
}

@end
