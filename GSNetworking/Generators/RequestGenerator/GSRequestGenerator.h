//
//  AXRequestGenerator.h
//  RTNetworking
//
//  Created by Brook on 2017/3/8.
//  Copyright © 2017年 BRBR Co ltd. All rights reserved.
//  NSURLRequest 请求构造器

#import <Foundation/Foundation.h>

@class GSRootRequest;
@interface GSRequestGenerator : NSObject

/// 共享实例
+ (instancetype)sharedGenerator;

/// 构造 NSURLRequest 对象，可输出错误信息
- (NSURLRequest *)prepareURLRequest:(GSRootRequest *)baseRequest error:(NSError * __autoreleasing *)error;

@end
