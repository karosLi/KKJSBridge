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

/**
 JSBridge 引擎，统一管理 webView 桥接，模块注册，JSBridge 配置和分发事件
 */
@interface KKJSBridgeEngine : NSObject

@property (nonatomic, weak, readonly) WKWebView *webView; // 与桥接器对应的 webView
@property (nonatomic, strong, readonly) KKJSBridgeModuleRegister *moduleRegister; // 模块注册者
@property (nonatomic, strong, readonly) KKJSBridgeConfig *config; // jsbridge 配置
@property (nonatomic, assign, getter=isBridgeReady) BOOL bridgeReady; // jsbridge 是否已经 ready

/**
 为 webView 创建一个桥接
 
 @param webView webView
 @return 返回一个桥接实例
 */
+ (instancetype)bridgeForWebView:(WKWebView *)webView;

/**
 分发一个事件

 @param eventName 事件名称
 @param data 数据
 */
- (void)dispatchEvent:(NSString *)eventName data:(NSDictionary * _Nullable)data;

@end

NS_ASSUME_NONNULL_END
