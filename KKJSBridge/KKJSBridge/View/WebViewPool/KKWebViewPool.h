//
//  KKWebViewPool.h
//  KKJSBridge
//
//  参考的是 HybridPageKit
//
//  Created by karos li on 2019/8/16.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class WKWebView;
@class WKWebViewConfiguration;

@interface KKWebViewPool : NSObject

+ (KKWebViewPool *)sharedInstance;

/**
 webView最大缓存数量
 默认为5个
 */
@property (nonatomic, assign, readwrite) NSInteger webViewMaxReuseCount;

/**
 webview进入回收复用池前加载的url，用于刷新webview和容错
 默认为空
 */
@property (nonatomic, copy, readwrite) NSString *webViewReuseLoadUrlStr;

/**
 webview最大重用次数
 默认为最大无限制
 */
@property (nonatomic, assign, readwrite) NSInteger webViewMaxReuseTimes;

/**
 获得一个可复用的webview
 
 @param webViewClass webview的自定义class
 @param webViewHolder webview的持有者，用于自动回收webview
 */
- (nullable __kindof WKWebView *)dequeueWebViewWithClass:(Class)webViewClass webViewHolder:(nullable NSObject *)webViewHolder;

/**
 构建 webView configuration，作为所有复用 webView 提供预先的默认 configuration
 
 @param block 构建 block
 */
- (void)makeWebViewConfiguration:(nullable void(^)(WKWebViewConfiguration *configuration))block;

/**
 创建一个 webview，并且将它放入到回收池中
 */
- (void)enqueueWebViewWithClass:(Class)webViewClass;

/**
 回收可复用的WKWebView
 
 @param webView 可复用的webView
 */
- (void)enqueueWebView:(nullable __kindof WKWebView *)webView;

/**
 回收并销毁WKWebView，并且将之从回收池里删除
 
 @param webView 可复用的webView
 */
- (void)removeReusableWebView:(nullable __kindof WKWebView *)webView;

/**
 销毁全部在回收池中的WebView
 */
- (void)clearAllReusableWebViews;

/**
 销毁在回收池中特定Class的WebView
 
 @param webViewClass 可复用的webView的类型
 */
- (void)clearAllReusableWebViewsWithClass:(Class)webViewClass;

/**
 重新刷新在回收池中的WebView
 */
- (void)reloadAllReusableWebViews;

/**
 判断回收池中是否包含特定Class的WebView
 
 @param webViewClass 可复用的webView的类型
 */
- (BOOL)containsReusableWebViewWithClass:(Class)webViewClass;

@end

NS_ASSUME_NONNULL_END
