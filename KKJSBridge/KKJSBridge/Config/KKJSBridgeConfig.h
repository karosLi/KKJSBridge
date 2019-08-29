//
//  KKJSBridgeConfig.h
//  KKJSBridge
//
//  Created by karos li on 2019/7/25.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KKJSBridgeAjaxDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/**
 配置 JSBridge 的行为，统一管理 Native 和 H5 侧对 JSBridge 的配置。
 */
@interface KKJSBridgeConfig : NSObject

#pragma mark - 用于记录外部设置
/**
 是否开启 ajax hook，默认是不开启的
 
 讨论：
 如果需要针对 enableAjaxHook 属性做联动的逻辑，可以监听（KVO/RAC）该属性的变化，比如当关闭 ajax hook 时，需要取消 WKWebView 对 http/https 的注册，避免有些场景下 ajax hook 引起了严重不兼容的问题，此时可以考虑在 H5 侧关闭该开关，宁可关闭对离线包的支持，也不能让这个页面不可用。
 */
@property (nonatomic, assign, getter=isEnableAjaxHook) BOOL enableAjaxHook;

/**
 ajax 请求回调管理器，一旦指定，JSBridge 引擎内部不会发送请求，而是把发送请求控制权交给该代理。前提是必须先开启 ajax hook。
 */
@property (nonatomic, weak) id<KKJSBridgeAjaxDelegateManager> ajaxDelegateManager;

@end

NS_ASSUME_NONNULL_END
