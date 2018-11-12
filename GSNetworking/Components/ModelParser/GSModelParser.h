//
//  GSModelParser.h
//  GSNetworking
//
//  Created by Brook on 2017/3/8.
//  Copyright © 2017年 BRBR Co ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GSModelParser : NSObject

/// 模型-> 集合
+ (id)gs_modelToJSONObject:(id)model;
/// 模型数组 -> 集合数组
+ (NSArray *)gs_modelsToJSONObjectArray:(NSArray *)modelArray;

/// 集合 -> 模型数组
+ (NSArray *)gs_arrayWithClass:(Class)clz
                responseObject:(id)responseObject
                         error:(NSError **)error;

/// 集合 -> 模型
+ (id)gs_modelWithClass:(Class)clz
         responseObject:(id)responseObject
                  error:(NSError **)error;

@end
