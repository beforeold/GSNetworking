//
//  NSData+GSImageMime.m
//  GSNetworkDemo
//
//  Created by Brook on 2017/3/13.
//  Copyright © 2017年 BRBR Co., LTD. All rights reserved.
//

#import "NSData+GSImageMime.h"
@implementation NSData (GSImageMime)

- (GSImageType)mimeType {
    if (self.length > 4) {
        const unsigned char * bytes = self.bytes;
        
        if (bytes[0] == 0xff &&
            bytes[1] == 0xd8 &&
            bytes[2] == 0xff)
        {
            return GSImageTypeJPEG;
        }
        
        if (bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4e &&
            bytes[3] == 0x47)
        {
            return GSImageTypePNG;
        }
    }
    
    return GSImageTypeOther;
}

@end
