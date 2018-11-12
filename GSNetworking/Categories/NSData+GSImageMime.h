//
//  NSData+GSImageMime.h
//  GSNetworkDemo
//
//  Created by Brook on 2017/3/13.
//  Copyright © 2017年 BRBR Co., LTD. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, GSImageType) {
    GSImageTypeJPEG,
    GSImageTypePNG,
    GSImageTypeOther,
};

@interface NSData (GSImageMime)

@property (nonatomic, assign, readonly) GSImageType mimeType;

@end
