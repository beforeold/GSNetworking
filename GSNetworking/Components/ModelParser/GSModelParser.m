//
//  GSModelParser.m
//  GSNetworking
//
//  Created by Brook on 2017/3/8.
//  Copyright © 2017年 BRBR Co ltd. All rights reserved.
//

#import "GSModelParser.h"
#import "NSError+HTTPErrorMessage.h"
#import <YYModel.h>

@implementation GSModelParser
#pragma mark -  API
+ (id)gs_modelToJSONObject:(id)model {
    if ([model isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray array];
        for (id submodel in model) {
            id jsonObject = [submodel yy_modelToJSONObject];
            if (jsonObject) [array addObject:jsonObject];
        }
        return array;
    }
    
    return [model yy_modelToJSONObject];
}

+ (NSArray *)gs_modelsToJSONObjectArray:(NSArray *)modelArray {
    NSMutableArray *objectArray = [NSMutableArray array];
    for (id model in modelArray) {
        id object = [self gs_modelToJSONObject:model];
        if (object) [objectArray addObject:object];
    }
    
    return [objectArray copy];
}

+ (id)gs_modelWithClass:(Class)clz responseObject:(id)responseObject error:(NSError **)error {
    id data = responseObject[@"data"];
    
    if (data == [NSNull null] || data == nil) {
        *error = [NSError http_nullOrNilDataErrorWithResponse:responseObject];
        return nil;
    }
    
    if (![data isKindOfClass:[NSDictionary class]]) {
        *error = [NSError http_unexpectedDataTypeErrorWithResponse:responseObject];
        return nil;
    }
    
    id responseModel = [self gs_modelWithDictionary:data class:clz];
    if (!responseModel) {
        *error = [NSError http_parsingErrorWithResponse:responseObject];
        return nil;
    }
    
    return responseModel;
}

+ (NSArray *)gs_arrayWithClass:(Class)clz responseObject:(id)responseObject error:(NSError **)error {
    id data = responseObject[@"data"];
    
    // 出现null时当做nil处理
    if (data == [NSNull null]) data = nil;
    
    BOOL isPossibleArray = [data isKindOfClass:[NSArray class]] || data == nil;
    if (!isPossibleArray) {
        *error = [NSError http_unexpectedDataTypeErrorWithResponse:responseObject];
        return nil;
    }
    
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary *dic in data) {
        id model = [self gs_modelWithDictionary:dic class:clz];
        if (model) [array addObject:model];
    }
    
    return [array copy];
}

#pragma mark - private
+ (id)gs_modelWithDictionary:(NSDictionary *)dic class:(Class)aClass {
    return [aClass yy_modelWithDictionary:dic];
}

@end
