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
@class KKJSBridgeEngine;

/**
 配置 JSBridge 的行为，统一管理 Native 和 H5 侧对 JSBridge 的配置。
 */
@interface KKJSBridgeConfig : NSObject

- (instancetype)initWithEngine:(KKJSBridgeEngine *)engine;

#pragma mark - 用于记录外部设置
/**
 是否开启 ajax hook，默认是不开启的
 
 讨论：
 当需要关闭 ajax hook 时，建议联动取消 WKWebView 对 http/https 的注册，这样可以避免有些场景下 ajax hook 引起了严重不兼容的问题，同事建议可以考虑在建立黑名单机制，让服务器端下发黑名单对部分页面关闭该开关，宁可关闭对离线包的支持，也不能让这个页面不可用。
 */
@property (nonatomic, assign, getter=isEnableAjaxHook) BOOL enableAjaxHook;

/**
 ajax 请求回调管理器，一旦指定，JSBridge 引擎内部不会发送请求，而是把发送请求控制权交给该代理。前提是必须先开启 ajax hook。
 
 请求代理没有必要一个 jsbridge 对应一个，而是所有 jsbridge 共用一个
 */
@property (class, nonatomic, weak) id<KKJSBridgeAjaxDelegateManager> ajaxDelegateManager;

@end

NS_ASSUME_NONNULL_END
