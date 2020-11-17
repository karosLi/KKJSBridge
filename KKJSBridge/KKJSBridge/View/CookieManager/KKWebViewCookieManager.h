//
//  KKWebViewCookieManager.h
//  KKJSBridge
//
//  Created by karos li on 2019/7/29.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class WKWebView;

@interface KKWebViewCookieManager : NSObject

/**
 用于同步首个同步请求的 cookie
 */
+ (void)syncRequestCookie:(NSMutableURLRequest *)request;

/**
 仅用于用于同步请求的 htp only cookie
*/
+ (void)onlySyncRequestHttpOnlyCookie:(NSMutableURLRequest *)request;
/**
 用于同步 ajax 请求的 cookie
 */
+ (NSString *)ajaxCookieScripts;
/**
 用于同步重定向请求的 cookie
 */
+ (NSMutableURLRequest *)fixRequest:(NSURLRequest *)request;

+ (void)copyNSHTTPCookieStorageToWKHTTPCookieStoreForWebViewOniOS11:(WKWebView *)webView withCompletion:(nullable void (^)(void))completion;

+ (void)copyWKHTTPCookieStoreToNSHTTPCookieStorageForWebViewOniOS11:(WKWebView *)webView withCompletion:(nullable void (^)(void))completion;

+ (NSDateFormatter *)cookieDateFormatter;

@end

NS_ASSUME_NONNULL_END
