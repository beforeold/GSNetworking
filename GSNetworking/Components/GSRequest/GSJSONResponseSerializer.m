//
//  GSJSONResponseSerializer.m
//  GSNetworkDemo
//
//  Created by Brook on 2017/5/13.
//  Copyright © 2017年 BRBR Co., LTD. All rights reserved.
//

#import "GSJSONResponseSerializer.h"

@implementation GSJSONResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    id responseObj = [super responseObjectForResponse:response data:data error:error];
    
    if (!responseObj && [self.delegate respondsToSelector:@selector(gsJSONResponseSerializer:didFailResponse:data:)]) {
        [self.delegate gsJSONResponseSerializer:self didFailResponse:response data:data];
    }
    
    return responseObj;
}

@end
