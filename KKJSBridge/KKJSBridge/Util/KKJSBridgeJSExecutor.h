//
//  KKJSBridgeJSExecutor.h
//  KKJSBridge
//
//  Created by karos li on 2019/7/23.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class WKWebView;

@interface KKJSBridgeJSExecutor : NSObject

+ (void)evaluateJavaScript:(NSString *)javaScriptString inWebView:(WKWebView *)webView completionHandler:(void (^ _Nullable)(_Nullable id result, NSError * _Nullable error))completionHandler;
+ (void)evaluateJavaScriptFunction:(NSString *)function withJson:(NSDictionary *)json inWebView:(WKWebView *)webView completionHandler:(void (^ _Nullable)(_Nullable id result, NSError * _Nullable error))completionHandler;
+ (void)evaluateJavaScriptFunction:(NSString *)function withString:(NSString *)string inWebView:(WKWebView *)webView completionHandler:(void (^ _Nullable)(_Nullable id result, NSError * _Nullable error))completionHandler;
+ (void)evaluateJavaScriptFunction:(NSString *)function withNumber:(NSNumber *)number inWebView:(WKWebView *)webView completionHandler:(void (^ _Nullable)(_Nullable id result, NSError * _Nullable error))completionHandler;
+ (NSString *)jsSerializeWithJson:(NSDictionary * _Nullable)json; // 序列化成 JS 可以执行的字符串
+ (NSString *)serializeWithJson:(NSDictionary * _Nullable)json pretty:(BOOL)pretty;

@end

NS_ASSUME_NONNULL_END
