//
//  WKWebView+KKJSBridgeEngine.h
//  KKJSBridge
//
//  Created by karos li on 2020/11/20.
//  Copyright © 2020 karosli. All rights reserved.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN
@class KKJSBridgeEngine;

/// 方便 WKWebView 获取 engine 做同步请求派发
@interface WKWebView (KKJSBridgeEngine)

/**
 KKJSBridgeEngine 在安装的时候，会赋值
 */
@property (nonatomic, weak) KKJSBridgeEngine *kk_engine;

/**
 处理同步调用
 */
- (BOOL)handleSyncCallWithPrompt:(NSString * _Nullable)prompt defaultText:(NSString * _Nullable)defaultText completionHandler:(void (^)(NSString * _Nullable result))completionHandler;

@end

NS_ASSUME_NONNULL_END
