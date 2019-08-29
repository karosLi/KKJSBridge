//
//  KKJSBridgeJSExecutor.m
//  KKJSBridge
//
//  Created by karos li on 2019/7/23.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "KKJSBridgeJSExecutor.h"
#import <WebKit/WebKit.h>

@implementation KKJSBridgeJSExecutor

+ (void)evaluateJavaScript:(NSString *)javaScriptString inWebView:(WKWebView *)webView completionHandler:(void (^ _Nullable)(_Nullable id result, NSError * _Nullable error))completionHandler {
    if ([[NSThread currentThread] isMainThread]) {
        __weak typeof(webView) weakWebView = webView;
        [webView evaluateJavaScript:javaScriptString completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            __strong typeof(weakWebView) strongWebView = weakWebView;
            [strongWebView title];
            if (completionHandler) {
                completionHandler(result, error);
            }
        }];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            __weak typeof(webView) weakWebView = webView;
            [webView evaluateJavaScript:javaScriptString completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                __strong typeof(weakWebView) strongWebView = weakWebView;
                [strongWebView title];
                if (completionHandler) {
                    completionHandler(result, error);
                }
            }];
        });
    }
}

+ (void)evaluateJavaScriptFunction:(NSString *)function withJson:(NSDictionary *)json inWebView:(WKWebView *)webView completionHandler:(void (^ _Nullable)(_Nullable id result, NSError * _Nullable error))completionHandler {
    NSString *messageString = [self jsSerializeWithJson:json];
    NSString *jsString = [NSString stringWithFormat:@"%@('%@')", function, messageString];
    [self evaluateJavaScript:jsString inWebView:webView completionHandler:completionHandler];
}

+ (void)evaluateJavaScriptFunction:(NSString *)function withString:(NSString *)string inWebView:(WKWebView *)webView completionHandler:(void (^ _Nullable)(_Nullable id result, NSError * _Nullable error))completionHandler {
    NSString *jsString = [NSString stringWithFormat:@"%@('%@')", function, string];
    [self evaluateJavaScript:jsString inWebView:webView completionHandler:completionHandler];
}

+ (void)evaluateJavaScriptFunction:(NSString *)function withNumber:(NSNumber *)number inWebView:(WKWebView *)webView completionHandler:(void (^ _Nullable)(_Nullable id result, NSError * _Nullable error))completionHandler {
    NSString *jsString = [NSString stringWithFormat:@"%@(%@)", function, number];
    [self evaluateJavaScript:jsString inWebView:webView completionHandler:completionHandler];
}

#pragma mark - util
+ (NSString *)jsSerializeWithJson:(NSDictionary * _Nullable)json {
    NSString *messageJSON = [self serializeWithJson:json ? json : @{} pretty:NO];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    
    return messageJSON;
}

+ (NSString *)serializeWithJson:(NSDictionary * _Nullable)json pretty:(BOOL)pretty {
    NSError *error = nil;
    NSString *str = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:json ? json : @{} options:(NSJSONWritingOptions)(pretty ? NSJSONWritingPrettyPrinted : 0) error:&error] encoding:NSUTF8StringEncoding];
#ifdef DEBUG
    if (error) {
        NSLog(@"KKJSBridge Error: format json error %@", error.localizedDescription);
    }
#endif
    
    return str ? str : @"";
}

@end
