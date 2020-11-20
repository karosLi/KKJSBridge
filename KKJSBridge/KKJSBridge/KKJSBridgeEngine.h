//
//  KKJSBridgeEngine.h
//  KKJSBridge
//
//  Created by karos li on 2019/7/19.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "KKJSBridgeModuleRegister.h"
#import "KKJSBridgeConfig.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^KKJSBridgeReadyCallback)(KKJSBridgeEngine *engine);

/**
 JSBridge 引擎，统一管理 webView 桥接，模块注册，JSBridge 配置和分发事件
 */
@interface KKJSBridgeEngine : NSObject

@property (nonatomic, weak, readonly) WKWebView *webView; // 与桥接器对应的 webView
@property (nonatomic, strong, readonly) KKJSBridgeModuleRegister *moduleRegister; // 模块注册者
@property (nonatomic, strong, readonly) KKJSBridgeConfig *config; // jsbridge 配置
@property (nonatomic, assign, getter=isBridgeReady) BOOL bridgeReady; // jsbridge 是否已经 ready
@property (nonatomic, copy) KKJSBridgeReadyCallback bridgeReadyCallback; // jsbridge ready callback

/**
 为 webView 创建一个桥接
 
 @param webView webView
 @return 返回一个桥接实例
 */
+ (instancetype)bridgeForWebView:(WKWebView *)webView;

/**
 分发一个事件到 H5

 @param eventName 事件名称
 @param data 数据
 */
- (void)dispatchEvent:(NSString *)eventName data:(NSDictionary * _Nullable)data;

/**
 分发一个调用。这个分发可以是来自 H5，也可以是来自 Native。
 
 讨论：
 如果使用的不是 KKWebView 而且自定义的 WKWebView，而又想要处理同步 JSBridge 调用，可以按下面方式来处理 JSBridge 同步调用。
 
 #import <KKJSBridge/KKJSBridge.h>
 
 - (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler {
     // 处理来自 KKJSBridge 的同步调用
     if ([self handleSyncCallWithPrompt:prompt defaultText:defaultText completionHandler:completionHandler]) {
         return;
     }
 }

 @param module 模块名
 @param method 方法名
 @param data 数据
 @param callback 回调
 */
- (void)dispatchCall:(NSString *)module method:(NSString *)method data:(NSDictionary * _Nullable)data callback:(void (^)(NSDictionary * _Nullable responseData))callback;

@end

NS_ASSUME_NONNULL_END
