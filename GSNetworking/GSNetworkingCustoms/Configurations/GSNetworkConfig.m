//
//  NetworkConfig.m
//
//  Copyright (c)  BRBR Co.ltd 

#import "GSNetworkConfig.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

@implementation GSNetworkConfig {
    NSMutableArray<id<GSURLFilterProtocol>> *_urlFilters;
    NSMutableArray<id<GSCacheDirPathFilterProtocol>> *_cacheDirPathFilters;
}

+ (GSNetworkConfig *)sharedConfig {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _baseURL = @"";
        _cdnURL = @"";
        _urlFilters = [NSMutableArray array];
        _cacheDirPathFilters = [NSMutableArray array];
        _securityPolicy = [AFSecurityPolicy defaultPolicy];
        _debugLogEnabled = NO;
    }
    return self;
}

- (void)addUrlFilter:(id<GSURLFilterProtocol>)filter {
    if (!filter) return;
    [_urlFilters addObject:filter];
}

- (void)clearUrlFilter {
    [_urlFilters removeAllObjects];
}

- (void)addCacheDirPathFilter:(id<GSCacheDirPathFilterProtocol>)filter {
    if (!filter) return;
    [_cacheDirPathFilters addObject:filter];
}

- (void)clearCacheDirPathFilter {
    [_cacheDirPathFilters removeAllObjects];
}

- (NSArray<id<GSURLFilterProtocol>> *)urlFilters {
    return [_urlFilters copy];
}

- (NSArray<id<GSCacheDirPathFilterProtocol>> *)cacheDirPathFilters {
    return [_cacheDirPathFilters copy];
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>{ baseURL: %@ } { cdnURL: %@ }", NSStringFromClass([self class]), self, self.baseURL, self.cdnURL];
}

@end
