//
//  GSJSONResponseSerializer.h
//  GSNetworkDemo
//
//  Created by Brook on 2017/5/13.
//  Copyright © 2017年 BRBR Co., LTD. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

@class GSJSONResponseSerializer;
@protocol GSJSONResponseSerializerDelegate <NSObject>

@optional
- (void)gsJSONResponseSerializer:(GSJSONResponseSerializer *)serializer
                 didFailResponse:(NSURLResponse *)response
                            data:(NSData *)data;

@end


@interface GSJSONResponseSerializer : AFJSONResponseSerializer

@property (nonatomic, weak) id <GSJSONResponseSerializerDelegate> delegate;

@end
