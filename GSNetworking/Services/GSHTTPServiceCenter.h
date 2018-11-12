//
//  AXServiceFactory.h
//  RTNetworking
//
//  Created by Brook on 2017/3/8.
//  Copyright © 2017年 BRBR Co ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GSHTTPService.h"

@interface GSHTTPServiceCenter : NSObject

+ (instancetype)defaultCenter;
- (GSNetService)serviceWithIdentifier:(NSString *)identifier;

@end
