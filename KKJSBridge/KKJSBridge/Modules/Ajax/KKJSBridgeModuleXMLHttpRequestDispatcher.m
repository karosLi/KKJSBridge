//
//  KKJSBridgeModuleXMLHttpRequest.m
//  KKJSBridge
//
//  Created by karos li on 2019/7/21.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "KKJSBridgeModuleXMLHttpRequestDispatcher.h"
#import "KKJSBridgeXMLHttpRequest.h"
#import "KKJSBridgeModuleRegister.h"
#import "KKJSBridgeEngine.h"

@interface KKJSBridgeModuleXMLHttpRequestDispatcher()<KKJSBridgeModule, KKJSBridgeModuleXMLHttpRequestDelegate>

@property (nonatomic, copy) NSMutableDictionary *xhrMap;
@property (nonatomic, copy) NSOperationQueue *queue;

@end

@implementation KKJSBridgeModuleXMLHttpRequestDispatcher

+ (nonnull NSString *)moduleName {
    return @"ajax";
}

+ (BOOL)isSingleton {
    return true;
}

- (instancetype)initWithEngine:(KKJSBridgeEngine *)engine context:(id)context {
    if (self = [super init]) {
        _xhrMap = [NSMutableDictionary dictionary];
        _queue = [NSOperationQueue new];
        _queue.maxConcurrentOperationCount = 1;
    }
    
    return self;
}

- (NSOperationQueue *)methodInvokeQueue {
    return self.queue;
}

- (void)create:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    NSNumber *objectId = params[@"id"];
    [self generateXHR:engine objectId:objectId responseCallback:responseCallback];
}

- (void)open:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    NSNumber *objectId = params[@"id"];
    KKJSBridgeXMLHttpRequest *xhr = [self getXHR:engine.webView objectId:objectId];
    if (!xhr) {
        xhr = [self generateXHR:engine objectId:objectId responseCallback:responseCallback];
    }
    NSString *method = params[@"method"];
    NSString *url = params[@"url"];
    NSString *userAgent = params[@"useragent"] ? params[@"useragent"] : @"iOS";
    NSString *referer = params[@"referer"];
    NSString *scheme = params[@"scheme"];
    NSString *host = params[@"host"];
    NSString *port = params[@"port"] ? params[@"port"] : @"";
    NSString *href = params[@"href"];
  
    NSURL *nativeURL = [NSURL URLWithString:url];
    if (!nativeURL.scheme) {
        /*------------兼容的代码 start------------*/
        // 说明是相对路径，一般是资源文件
        //        示例1
        //        {
        //            async = 1;
        //            host = "m.feng1.com";
        //            href = "https://m.feng1.com/mall/app/index.html?channel=SFIM&ddsds=ewew#2222";
        //            id = 632;
        //            method = GET;
        //            port = "";
        //            referer = "<null>";
        //            scheme = "https:";
        //            url = "/api/mall/channelConfig/getChannelThemeConfig?channel=SFIM&_=1578133077103";
        //            useragent = "Mozilla/5.0 (iPhone; CPU iPhone OS 12_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/16A366";
        //        }
        //
        //        示例2
        //        {
        //            async = 1;
        //            host = "";
        //            href = "file:///Users/01388087/Library/Developer/CoreSimulator/Devices/B9133CAF-51E9-456E-92F6-FAC6EFC676AB/data/Containers/Data/Application/5BCBB3E7-A35F-4BCD-89B7-A79474C0E2C8/Documents/c6a5a31f3f1d9e446353e0425ab55c3e/2e6cda38b47d8c6ec672a1ed4f66cfe8/b8c37e33defde51cf91e1e03e51657da/UnityFile/Cache/serviceApp/packages/salary/f99bb68cfd2680c098a287fca1182030/www/index.html#/dsdsds/ddd?key=xxx&eewwe";
        //            id = 496;
        //            method = GET;
        //            port = "";
        //            referer = "<null>";
        //            scheme = "file:";
        //            url = "views/salaryInquiry/ssf-account-edit.html";
        //            useragent = "Mozilla/5.0 (iPhone; CPU iPhone OS 12_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/16A366";
        //        }
                
        // 先按照?截取，然后按照#截取
        NSString* path = [href componentsSeparatedByString:@"?"][0]; // 按“?”进行分割，获取第一个字符串
        path = [path componentsSeparatedByString:@"#"][0]; // 按“#”进行分割，获取第一个字符串
        path = [path stringByDeletingLastPathComponent]; // 删除最后一个“/”之后的内容，获取到当前文件的相对路径

        if ([scheme hasPrefix:@"file:"]) {
            // 本地相对路径
            if (![url hasPrefix:@"/"]){
                path = [NSString stringWithFormat:@"%@/",path];
            }
            // 完整路径
            url = [NSString stringWithFormat:@"%@%@",path,url];
        }else{
            // 网络相对路径
            if (![url hasPrefix:@"/"]){
               url = [NSString stringWithFormat:@"%@%@",path,url];
            }else {
               // 网络路径，拼接host
               NSString *tmpPort = port.length > 0 ? [NSString stringWithFormat:@":%@", port] : @"";
               url = [NSString stringWithFormat:@"%@//%@%@%@",scheme, host, tmpPort, url];
            }
        }
        
        
//        if (nativeURL.pathComponents > 0) {
//            if (nativeURL.host) {
//                url = [NSString stringWithFormat:@"%@%@",scheme, url];
//            } else {
//                if ([url hasPrefix:@"/"]) {// 处理 【/】情况
//                    NSString *tmpPath = url;
//                    NSString *tmpPort = port.length > 0 ? [NSString stringWithFormat:@":%@", port] : @"";
//                    url = [NSString stringWithFormat:@"%@//%@%@%@",scheme, host, tmpPort, tmpPath];
//                } else { // 处理 【./】 【../】 【../../】和前面没有前缀的情况
//                    url = [[href stringByAppendingPathComponent:url] stringByStandardizingPath];
//                }
//            }
//        } else {
//            url = href;
//        }
    }
    
    [xhr open:method url:url userAgent:userAgent referer:referer];
}

- (void)send:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    NSNumber *objectId = params[@"id"];
    KKJSBridgeXMLHttpRequest *xhr = [self getXHR:engine.webView objectId:objectId];
    if (xhr) {
        id data = params[@"data"];
        BOOL isByteData = [params[@"isByteData"] boolValue];
        BOOL isFormData = [params[@"isFormData"] boolValue];
        if (data) {
            if (isByteData && [data isKindOfClass:NSArray.class]) { // 字节数据特殊处理
                NSArray *arrayData = (NSArray *)data;
                NSData *byteData = [self convertToDataFromUInt8Array:arrayData];
                [xhr send:byteData];
            } else if (isFormData) { // 表单特殊处理
                NSArray<NSString *> *fileKeys = data[@"fileKeys"];
                NSArray<NSArray *> *formData = data[@"formData"];
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
                        if ([fileJson[@"data"] isKindOfClass:NSString.class]) {
                            NSString *base64 = (NSString *)fileJson[@"data"];
                            NSData *byteData = [self convertToDataFromBase64:base64];
                            fileData.data = byteData;
                        }
                        
                        [fileDatas addObject:fileData];
                    } else {
                        params[key] = pair[1];
                    }
                }
                
                [xhr sendFormData:params withFileDatas:fileDatas];
            } else {
                [xhr send:data];
            }
        } else {
            [xhr send];
        }
    }
}

- (NSData *)convertToDataFromUInt8Array:(NSArray<NSNumber *> *)array {
    UInt8 bytes[array.count];
    for (NSInteger i = 0; i< array.count; i++) {
        NSNumber *obj = array[i];
        UInt8 byte = (UInt8)obj.intValue;
        bytes[i] = byte;
    }
    
    NSData *byteData= [NSData dataWithBytes:bytes length:array.count];
    return byteData;
}

- (NSData *)convertToDataFromBase64:(NSString *)base64 {
    // data:image/png;base64,iVBORw0...
    NSArray<NSString *> *components = [base64 componentsSeparatedByString:@","];
    if (components.count != 2) {
        return nil;
    }
    
    NSString *splitBase64 = components.lastObject;
    NSUInteger paddedLength = splitBase64.length + (splitBase64.length % 4);
    NSString *fixBase64 = [splitBase64 stringByPaddingToLength:paddedLength withString:@"=" startingAtIndex:0];
    NSData *data = [[NSData alloc] initWithBase64EncodedString:fixBase64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    return data;
}

- (void)setRequestHeader:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    NSNumber *objectId = params[@"id"];
    KKJSBridgeXMLHttpRequest *xhr = [self getXHR:engine.webView objectId:objectId];
    if (xhr) {
        NSString *headerName = params[@"headerName"];
        id headerValue = params[@"headerValue"];
        NSString *headerValueString = @"";
        if ([headerValue isKindOfClass:[NSString class]]) {
            headerValueString = headerValue;
        } else if([headerValue isKindOfClass:[NSNumber class]]) {
            headerValueString = [(NSNumber *)headerValue stringValue];
        }
        [xhr setRequestHeader:headerName headerValue:headerValueString];
    }
}

- (void)overrideMimeType:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    NSNumber *objectId = params[@"id"];
    KKJSBridgeXMLHttpRequest *xhr = [self getXHR:engine.webView objectId:objectId];
    if (xhr) {
        [xhr overrideMimeType:params[@"mimetype"]];
    }
}

- (void)abort:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    NSNumber *objectId = params[@"id"];
    KKJSBridgeXMLHttpRequest *xhr = [self getXHR:engine.webView objectId:objectId];
    if (xhr) {
        [xhr abort];
    }
}

#pragma mark - KKJSBridgeXMLHttpRequestDelegate
- (void)notifyDispatcherFetchComplete:(KKJSBridgeXMLHttpRequest*)xmlHttpRequest {
    [self freeXMLHttpRequestObject:xmlHttpRequest.webView objectId:xmlHttpRequest.objectId];
}

- (void)notifyDispatcherFetchFailed:(KKJSBridgeXMLHttpRequest*)xmlHttpRequest {
    [self freeXMLHttpRequestObject:xmlHttpRequest.webView objectId:xmlHttpRequest.objectId];
}

#pragma mark - util
- (KKJSBridgeXMLHttpRequest *)generateXHR:(KKJSBridgeEngine *)engine objectId:(NSNumber *)objectId responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    KKJSBridgeXMLHttpRequest *xhr = [[KKJSBridgeXMLHttpRequest alloc] initWithObjectId:objectId engine:engine];
    xhr.delegate = self;
    
    [self.xhrMap setValue:xhr forKey:[self uniqueIdWithWebView:engine.webView objectId:objectId]];
    
    return xhr;
}

- (KKJSBridgeXMLHttpRequest *)getXHR:(WKWebView *)webView objectId:(NSNumber *)objectId {
    KKJSBridgeXMLHttpRequest *xhr = self.xhrMap[[self uniqueIdWithWebView:webView objectId:objectId]];
    
    return xhr;
}

- (void)freeXMLHttpRequestObject:(WKWebView *)webView objectId:(NSNumber *)objectId {
    if (objectId) {
        NSString *uniqueString = [self uniqueIdWithWebView:webView objectId:objectId];
        [KKJSBridgeXMLHttpRequest evaluateJSToDeleteAjaxCache:objectId inWebView:webView];
        [self.xhrMap removeObjectForKey:uniqueString];
    }
}

- (NSString *)uniqueIdWithWebView:(WKWebView *)webView objectId:(NSNumber *)objectId {
    return [NSString stringWithFormat:@"%lu%@", (unsigned long)webView.hash, [objectId stringValue]];
}

@end
