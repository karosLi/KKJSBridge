//
//  KKJSBridgeAjaxBodyHelper.m
//  KKJSBridge
//
//  Created by karos li on 2020/7/9.
//  Copyright © 2020 karosli. All rights reserved.
//

#import "KKJSBridgeAjaxBodyHelper.h"
#import "KKJSBridgeFormDataFile.h"
#import "KKJSBridgeURLRequestSerialization.h"

@implementation KKJSBridgeAjaxBodyHelper

/**
 
 type BodyType = "String" | "Blob" | "FormData" | "ArrayBuffer";
 type FormEnctype = "application/x-www-form-urlencoded" | "text/plain" | "multipart/form-data" | string;
 
 {
    //请求唯一id
    requestId,
    //当前 href url
    requestHref,
    //请求 Url
    requestUrl,
    //body 类型
    bodyType
    //表单编码类型
    formEnctype
    //body 具体值
    value
}
*/
+ (void)setBodyRequest:(NSDictionary *)bodyRequest toRequest:(NSMutableURLRequest *)request {
    NSData *data = nil;
    NSString *bodyType = bodyRequest[@"bodyType"];
    NSString *formEnctype = bodyRequest[@"formEnctype"];
    id value = bodyRequest[@"value"];
    if (!value) {
        return;
    }
    
    if ([bodyType isEqualToString:@"Blob"]) {
        data = [self dataFromBase64:value];
    } else if ([bodyType isEqualToString:@"ArrayBuffer"]) {
        data = [self dataFromBase64:value];
    } else if ([bodyType isEqualToString:@"FormData"]) {
        [self setFormData:value formEnctype:formEnctype toRequest:request];
        return;
    } else {//String
        if ([value isKindOfClass:NSDictionary.class]) {
            // application/json
            data = [NSJSONSerialization dataWithJSONObject:value options:0 error:nil];
        } else if ([value isKindOfClass:NSString.class]) {
            // application/x-www-form-urlencoded
            // name1=value1&name2=value2
            data = [value dataUsingEncoding:NSUTF8StringEncoding];
        } else {
            data = value;
        }
    }
    
    request.HTTPBody = data;
}

+ (NSData *)dataFromBase64:(NSString *)base64 {
    if (!base64) {
        return [NSData data];
    }
    
    // data:image/png;base64,iVBORw0...
    NSArray<NSString *> *components = [base64 componentsSeparatedByString:@","];
    
    NSString *splitBase64;
    if (components.count == 2) {
        splitBase64 = components.lastObject;
    } else {
        splitBase64 = base64;
    }
    
    NSUInteger paddedLength = splitBase64.length + (splitBase64.length % 4);
    NSString *fixBase64 = [splitBase64 stringByPaddingToLength:paddedLength withString:@"=" startingAtIndex:0];
    NSData *data = [[NSData alloc] initWithBase64EncodedString:fixBase64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    return data;
}

+ (void)setFormData:(NSDictionary *)formDataJson formEnctype:(NSString *)formEnctype toRequest:(NSMutableURLRequest *)request {
//     type FormEnctype = "application/x-www-form-urlencoded" | "text/plain" | "multipart/form-data" | string;
    
    NSArray<NSString *> *fileKeys = formDataJson[@"fileKeys"];
    NSArray<NSArray *> *formData = formDataJson[@"formData"];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSMutableArray<KKJSBridgeFormDataFile *> *fileDatas = [NSMutableArray array];
    
    for (NSArray *pair in formData) {
        if (pair.count < 2) {
            continue;
        }
        
        NSString *key = pair[0];
        if ([fileKeys containsObject:key]) {// 说明存储的是个文件数据
            NSDictionary *fileJson = pair[1];
            KKJSBridgeFormDataFile *fileData = [KKJSBridgeFormDataFile new];
            fileData.key = key;
            fileData.size = [fileJson[@"size"] unsignedIntegerValue];
            fileData.type = fileJson[@"type"];
            
            if (fileJson[@"name"] && [fileJson[@"name"] length] > 0) {
                fileData.fileName = fileJson[@"name"];
            } else {
                fileData.fileName = fileData.key;
            }
            if (fileJson[@"lastModified"] && [fileJson[@"lastModified"] unsignedIntegerValue] > 0) {
                fileData.lastModified = [fileJson[@"lastModified"] unsignedIntegerValue];
            }
            
            if ([formEnctype isEqualToString:@"multipart/form-data"]) {
                if ([fileJson[@"data"] isKindOfClass:NSString.class]) {
                    NSString *base64 = (NSString *)fileJson[@"data"];
                    NSData *byteData = [self dataFromBase64:base64];
                    fileData.data = byteData;
                }
                
                [fileDatas addObject:fileData];
            } else {
                params[key] = fileData.fileName;
            }
        } else {
            params[key] = pair[1];
        }
    }
    
    if ([formEnctype isEqualToString:@"multipart/form-data"]) {
        KKJSBridgeURLRequestSerialization *serializer = [self urlRequestSerialization];
        [serializer multipartFormRequestWithRequest:request parameters:params constructingBodyWithBlock:^(id<KKJSBridgeMultipartFormData>  _Nonnull formData) {
            for (KKJSBridgeFormDataFile *fileData in fileDatas) {
                [formData appendPartWithFileData:fileData.data name:fileData.key fileName:fileData.fileName mimeType:fileData.type];
            }
        } error:nil];
    } else if ([formEnctype isEqualToString:@"text/plain"]) {
        NSMutableString *string = [NSMutableString new];
        NSString *lastKey = params.allKeys.lastObject;
        for (NSString *key in params.allKeys) {
            [string appendFormat:@"%@=%@", [self percentEscapedStringFromString:key], [self percentEscapedStringFromString:params[key]]];
            if (![key isEqualToString:lastKey]) {
                [string appendString:@"\r\n"];
            }
        }
        
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        request.HTTPBody = data;
    } else {// application/x-www-form-urlencoded
        NSMutableString *string = [NSMutableString new];
        NSString *lastKey = params.allKeys.lastObject;
        for (NSString *key in params.allKeys) {
            [string appendFormat:@"%@=%@", [self percentEscapedStringFromString:key], [self percentEscapedStringFromString:params[key]]];
            if (![key isEqualToString:lastKey]) {
                [string appendString:@"&"];
            }
        }
        
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        request.HTTPBody = data;
    }
}

/**
 参考AFN
 
 Returns a percent-escaped string following RFC 3986 for a query string key or value.
 RFC 3986 states that the following characters are "reserved" characters.
    - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
    - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="

 In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
 query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
 should be percent-escaped in the query string.
    - parameter string: The string to be percent-escaped.
    - returns: The percent-escaped string.
 */
+ (NSString *)percentEscapedStringFromString:(NSString *)string {
    static NSString * const kAFCharactersGeneralDelimitersToEncode = @":#[]@"; // does not include "?" or "/" due to RFC 3986 - Section 3.4
    static NSString * const kAFCharactersSubDelimitersToEncode = @"!$&'()*+,;=";

    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kAFCharactersGeneralDelimitersToEncode stringByAppendingString:kAFCharactersSubDelimitersToEncode]];

    // FIXME: https://github.com/AFNetworking/AFNetworking/pull/3028
    // return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];

    static NSUInteger const batchSize = 50;

    NSUInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;

    while (index < string.length) {
        NSUInteger length = MIN(string.length - index, batchSize);
        NSRange range = NSMakeRange(index, length);

        // To avoid breaking up character sequences such as 👴🏻👮🏽
        range = [string rangeOfComposedCharacterSequencesForRange:range];

        NSString *substring = [string substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];

        index += range.length;
    }

    return escaped;
}

#pragma mark - KKJSBridgeURLRequestSerialization

+ (KKJSBridgeURLRequestSerialization *)urlRequestSerialization {
    static KKJSBridgeURLRequestSerialization *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [KKJSBridgeURLRequestSerialization new];
    });
    
    return instance;
}

@end
