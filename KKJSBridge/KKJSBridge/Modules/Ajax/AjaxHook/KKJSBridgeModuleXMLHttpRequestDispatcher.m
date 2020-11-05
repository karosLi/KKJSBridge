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
#import "KKJSBridgeFormDataFile.h"
#import "KKJSBridgeSafeDictionary.h"

@interface KKJSBridgeModuleXMLHttpRequestDispatcher()<KKJSBridgeModule, KKJSBridgeModuleXMLHttpRequestDelegate>

@property (nonatomic, copy) KKJSBridgeSafeDictionary *xhrMap;
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
        _xhrMap = [KKJSBridgeSafeDictionary dictionary];
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
        if (nativeURL.pathComponents > 0) {
            if (nativeURL.host) {
                url = [NSString stringWithFormat:@"%@%@",scheme, url];
            } else {
                if ([url hasPrefix:@"/"]) {// 处理 【/】情况
                    NSString *tmpPath = url;
                    NSString *tmpPort = port.length > 0 ? [NSString stringWithFormat:@":%@", port] : @"";
                    url = [NSString stringWithFormat:@"%@//%@%@%@",scheme, host, tmpPort, tmpPath];
                } else { // 处理 【./】 【../】 【../../】和前面没有前缀的情况
                    NSURL *newUrl = [NSURL URLWithString:url relativeToURL:[NSURL URLWithString:href]];
                    url = newUrl.absoluteString;
                }
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
        [xhr send:params];
    }
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
