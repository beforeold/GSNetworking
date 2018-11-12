//
//  GSNetworkEnum.h
//  GSNetworkDemo
//
//  Created by Brook on 2017/3/10.
//  Copyright © 2017年 BRBR Co., LTD. All rights reserved.
//

#ifndef GSNetworkEnum_h
#define GSNetworkEnum_h

///  HTTP Request method.
typedef NS_ENUM(NSInteger, GSRequestMethod) {
    GSRequestMethodGET = 0,
    GSRequestMethodPOST,
    GSRequestMethodHEAD,
    GSRequestMethodPUT,
    GSRequestMethodDELETE,
    GSRequestMethodPATCH,
};

///  Request serializer type.
typedef NS_ENUM(NSInteger, GSRequestSerializerType) {
    GSRequestSerializerTypeHTTP = 0,
    GSRequestSerializerTypeJSON,
};

///  Response serializer type, which determines response serialization process and
///  the type of `responseObject`.
typedef NS_ENUM(NSInteger, GSResponseSerializerType) {
    /// NSData type
    GSResponseSerializerTypeHTTP,
    /// JSON object type
    GSResponseSerializerTypeJSON,
    /// NSXMLParser type
    GSResponseSerializerTypeXMLParser,
};

typedef NS_ENUM(NSInteger, GSExpectedResultType) {
    GSExpectedResultTypeNone,
    GSExpectedResultTypeOne,
    GSExpectedResultTypeList,
};

#endif /* GSNetworkEnum_h */
