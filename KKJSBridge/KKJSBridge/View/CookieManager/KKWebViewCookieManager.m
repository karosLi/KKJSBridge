//
//  KKWebViewCookieManager.m
//  KKJSBridge
//
//  Created by karos li on 2019/7/29.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "KKWebViewCookieManager.h"
#import <WebKit/WebKit.h>

@implementation KKWebViewCookieManager

+ (void)syncRequestCookie:(NSMutableURLRequest *)request {
    if (!request.URL) {
        return;
    }
    
    NSArray<NSHTTPCookie *> *availableCookie = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:request.URL];
    if (availableCookie.count > 0) {
        NSDictionary *reqHeader = [NSHTTPCookie requestHeaderFieldsWithCookies:availableCookie];
        NSString *cookieStr = [reqHeader objectForKey:@"Cookie"];
        [request setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    }
}

+ (void)onlySyncRequestHttpOnlyCookie:(NSMutableURLRequest *)request {
    if (!request.URL) {
        return;
    }
    
    NSArray<NSHTTPCookie *> *availableCookie = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:request.URL];
    if (availableCookie.count > 0) {
        NSMutableString *cookieStr = [[request valueForHTTPHeaderField:@"Cookie"] mutableCopy];
        if (!cookieStr) {
            cookieStr = [[NSMutableString alloc] init];
        }
        for (NSHTTPCookie *cookie in availableCookie) {
            if (!cookie.isHTTPOnly) {
                continue;
            }
            [cookieStr appendFormat:@"%@=%@;", cookie.name, cookie.value];
        }
        [request setValue:cookieStr forHTTPHeaderField:@"Cookie"];
    }
}

+ (NSString *)ajaxCookieScripts {
    NSMutableString *cookieScript = [[NSMutableString alloc] init];
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        // Skip cookies that will break our script
        if ([cookie.value rangeOfString:@"'"].location != NSNotFound) {
            continue;
        }
        // Create a line that appends this cookie to the web view's document's cookies
        [cookieScript appendFormat:@"document.cookie='%@=%@;", cookie.name, cookie.value];
        if (cookie.domain || cookie.domain.length > 0) {
            [cookieScript appendFormat:@"domain=%@;", cookie.domain];
        }
        if (cookie.path || cookie.path.length > 0) {
            [cookieScript appendFormat:@"path=%@;", cookie.path];
        }
        if (cookie.expiresDate) {
            [cookieScript appendFormat:@"expires=%@;", [[self cookieDateFormatter] stringFromDate:cookie.expiresDate]];
        }
        if (cookie.secure) {
            // 只有 https 请求才能携带该 cookie
            [cookieScript appendString:@"Secure;"];
        }
        if (cookie.HTTPOnly) {
            // 保持 native 的 cookie 完整性，当 HTTPOnly 时，不能通过 document.cookie 来读取该 cookie。
            [cookieScript appendString:@"HTTPOnly;"];
        }
        [cookieScript appendFormat:@"'\n"];
    }
    
    return cookieScript;
}

+ (NSMutableURLRequest *)fixRequest:(NSURLRequest *)request {
    NSMutableURLRequest *fixedRequest;
    if ([request isKindOfClass:[NSMutableURLRequest class]]) {
        fixedRequest = (NSMutableURLRequest *)request;
    } else {
        fixedRequest = request.mutableCopy;
    }
    
    NSMutableArray *array = [NSMutableArray array];
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:request.URL]) {
        NSString *value = [NSString stringWithFormat:@"%@=%@", cookie.name, cookie.value];
        [array addObject:value];
    }

    NSString *cookie = [array componentsJoinedByString:@";"];
    [fixedRequest setValue:cookie forHTTPHeaderField:@"Cookie"];
    return fixedRequest;
}

+ (void)copyNSHTTPCookieStorageToWKHTTPCookieStoreForWebViewOniOS11:(WKWebView *)webView withCompletion:(nullable void (^)(void))completion {
    if (@available(iOS 11.0, *)) {
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
        WKHTTPCookieStore *cookieStroe = webView.configuration.websiteDataStore.httpCookieStore;
        if (cookies.count == 0) {
            completion ? completion() : nil;
            return;
        }
        for (NSHTTPCookie *cookie in cookies) {
            [cookieStroe setCookie:cookie completionHandler:^{
                if ([[cookies lastObject] isEqual:cookie]) {
                    completion ? completion() : nil;
                    return;
                }
            }];
        }
    }
}

+ (void)copyWKHTTPCookieStoreToNSHTTPCookieStorageForWebViewOniOS11:(WKWebView *)webView withCompletion:(nullable void (^)(void))completion {
    if (@available(iOS 11.0, *)) {
        WKHTTPCookieStore *cookieStroe = webView.configuration.websiteDataStore.httpCookieStore;
        [cookieStroe getAllCookies:^(NSArray<NSHTTPCookie *> * _Nonnull cookies) {
            if (cookies.count == 0) {
                completion ? completion() : nil;
                return;
            }
            for (NSHTTPCookie *cookie in cookies) {
                [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
                if ([[cookies lastObject] isEqual:cookie]) {
                    completion ? completion() : nil;
                    return;
                }
            }
        }];
    }
}

+ (NSDateFormatter *)cookieDateFormatter {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // expires=Mon, 01 Aug 2050 06:44:35 GMT
        formatter = [NSDateFormatter new];
        formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        formatter.dateFormat = @"EEE, d MMM yyyy HH:mm:ss zzz";
    });
    
    return formatter;
}

@end
