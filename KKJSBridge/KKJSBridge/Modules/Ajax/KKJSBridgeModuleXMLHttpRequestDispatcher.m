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
@property (nonatomic, copy) NSLock *lock;

@end

@implementation KKJSBridgeModuleXMLHttpRequestDispatcher

+ (nonnull NSString *)moduleName {
    return @"ajax";
}

+ (BOOL)isSingleton {
    return true;
}

+ (NSOperationQueue *)methodInvokeQueue {
    static NSOperationQueue *queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [NSOperationQueue new];
    });
    
    return queue;
}

- (instancetype)initWithEngine:(KKJSBridgeEngine *)engine context:(id)context {
    if (self = [super init]) {
        _xhrMap = [NSMutableDictionary dictionary];
        _lock = [NSLock new];
    }
    
    return self;
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
        if (nativeURL.pathComponents > 0) {
            if (nativeURL.host) {
                url = [NSString stringWithFormat:@"%@%@",scheme, url];
            } else {
                NSString *tmpPath = [url hasPrefix:@"/"] ? url : [NSString stringWithFormat:@"/%@", url];
                NSString *tmpPort = port.length > 0 ? [NSString stringWithFormat:@":%@", port] : @"";
                url = [NSString stringWithFormat:@"%@//%@%@%@",scheme, host, tmpPort, tmpPath];
            }
        } else {
            url = href;
        }
    }
    
    [xhr open:method url:url userAgent:userAgent referer:referer];
}

- (void)send:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    NSNumber *objectId = params[@"id"];
    KKJSBridgeXMLHttpRequest *xhr = [self getXHR:engine.webView objectId:objectId];
    if (xhr) {
        id data = params[@"data"];
        BOOL isByteData = [params[@"isByteData"] boolValue];
        if (data) {
            if (isByteData && [data isKindOfClass:NSArray.class]) {
                NSArray *arrayData = (NSArray *)data;
                NSData *byteData = [self convertToDataFromUInt8Array:arrayData];
                [xhr send:byteData];
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
    
    [self.lock lock];
    [self.xhrMap setValue:xhr forKey:[self uniqueIdWithWebView:engine.webView objectId:objectId]];
    [self.lock unlock];
    
    return xhr;
}

- (KKJSBridgeXMLHttpRequest *)getXHR:(WKWebView *)webView objectId:(NSNumber *)objectId {
    [self.lock lock];
    KKJSBridgeXMLHttpRequest *xhr = self.xhrMap[[self uniqueIdWithWebView:webView objectId:objectId]];
    [self.lock unlock];
    
    return xhr;
}

- (void)freeXMLHttpRequestObject:(WKWebView *)webView objectId:(NSNumber *)objectId {
    if (objectId) {
        [self.lock lock];
        NSString *uniqueString = [self uniqueIdWithWebView:webView objectId:objectId];
        [KKJSBridgeXMLHttpRequest evaluateJSToDeleteAjaxCache:objectId inWebView:webView];
        [self.xhrMap removeObjectForKey:uniqueString];
        [self.lock unlock];
    }
}

- (NSString *)uniqueIdWithWebView:(WKWebView *)webView objectId:(NSNumber *)objectId {
    return [NSString stringWithFormat:@"%lu%@", (unsigned long)webView.hash, [objectId stringValue]];
}

@end
