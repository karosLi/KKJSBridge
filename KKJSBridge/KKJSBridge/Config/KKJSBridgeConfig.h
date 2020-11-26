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
 1、当需要关闭 ajax hook 时，建议联动取消 WKWebView 对 http/https 的注册，这样可以避免有些场景下 ajax hook 引起了严重不兼容的问题。
 2、同时建议可以考虑建立黑名单机制，让服务器端下发黑名单对部分页面关闭该开关，宁可关闭对离线包的支持，也不能让这个页面不可用。
 */
@property (nonatomic, assign, getter=isEnableAjaxHook) BOOL enableAjaxHook;

/**
 是否开启 cookie set hook，默认是开启的

 讨论：
 1、当开启 cookie set hook 时，document.cookie 的修改会通过异步 JSBridge 调用保存到 NSHTTPCookieStorage。
 2、建议是开启的，因为任何场景下都是需要把手动设置的 cookie 同步给 NSHTTPCookieStorage。
 
 Cookie 管理的理解：
 NSHTTPCookieStorage 是唯一读取和存储 Cookie 的仓库，此时是可以不用保证 WKWebView Cookie 是否是最新的，只需要保证 NSHTTPCookieStorage 是最新的，并且每个请求从 NSHTTPCookieStorage 读取 Cookie 即可。因为既然已经代理了请求，就应该全权使用 NSHTTPCookieStorage 存储的 Cookie，来避免 WKWebView 的 Cookie 不是最新的问题。
*/
@property (nonatomic, assign, getter=isEnableCookieSetHook) BOOL enableCookieSetHook;

/**
 是否开启 cookie get hook，默认是开启的
 
 讨论：
 1、当同时开启了 ajax hook 和 cookie get hook，才需要把 document.cookie 的读取通过同步 JSBridge 调用从 NSHTTPCookieStorage 中读取 cookie。因为当非 ajax hook 情况下，说明是纯 WKWebView 的场景，那么 ajax 响应头里 Set-Cookie 只会存储在 WKCookie 里，所以此时是只能直接从 WKCookie 里读取 cookie 的。
 2、这里单独把 cookie get hook 作为开关，是因为并不是所有的 H5 项目都是通过 document.cookie 去读取最新的 cookie，并做一些业务判断的，所以在这个情况下，是可以不用 hook cookie get 方法的。建议根据自己项目实际情况来决定是否需要开启 cookie get hook。
 */
@property (nonatomic, assign, getter=isEnableCookieGetHook) BOOL enableCookieGetHook;

/**
 ajax 请求回调管理器，一旦指定，JSBridge 引擎内部不会发送请求，而是把发送请求控制权交给该代理。前提是必须先开启 ajax hook。
 
 请求代理没有必要一个 JSBridge 对应一个，而是所有 JSBridge 共用一个
 */
@property (class, nonatomic, weak) id<KKJSBridgeAjaxDelegateManager> ajaxDelegateManager;

@end

NS_ASSUME_NONNULL_END
