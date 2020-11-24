//
//  KKJSBridgeModuleCookie.m
//  KKJSBridge
//
//  Created by karos li on 2019/8/1.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "KKJSBridgeModuleCookie.h"
#import "KKJSBridgeModuleRegister.h"
#import "KKJSBridgeEngine.h"
#import "KKWebViewCookieManager.h"

@interface KKJSBridgeModuleCookie()<KKJSBridgeModule>

@property (nonatomic, copy) NSOperationQueue *queue;

@end

@implementation KKJSBridgeModuleCookie

+ (nonnull NSString *)moduleName {
    return @"cookie";
}

+ (BOOL)isSingleton {
    return true;
}

- (instancetype)initWithEngine:(KKJSBridgeEngine *)engine context:(id)context {
    if (self = [super init]) {
        _queue = [NSOperationQueue new];
    }
    
    return self;
}

- (NSOperationQueue *)methodInvokeQueue {
    return self.queue;
}

// 用于确定 jsbridge 已经准备好了
- (void)bridgeReady:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    // nothing
}

/**
 Hook cookie 修改操作，把 WKWebView cookie 同步给 NSHTTPCookieStorage
 
 比如：
 H5 控制台执行如下语句
 > document.cookie='qq=55x; domain=172.16.12.72; path=/; expires=Mon, 01 Aug 2050 06:44:35 GMT; Secure'
 
 就会触发下方方法的调用。执行完方法后，可以去查看 cookie 同步的结果：
 > Python BinaryCookieReader.py ./Cookies.binarycookies
 Cookie : qq=55 x; domain=172.16.12.72; path=/; expires=Mon, 01 Aug 2050; Secure
 
 > Python BinaryCookieReader.py ./com.xxx.KKWebview.binarycookies
 Cookie : qq=55 x; domain=172.16.12.72; path=/; expires=Mon, 01 Aug 2050; Secure
 
 */
- (void)setCookie:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    NSString *cookieString = params[@"cookie"];
    if (![cookieString isKindOfClass:NSString.class] || cookieString.length == 0) {
        return;
    }
    
    NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithCapacity:6];
    NSArray<NSString *> *segements = [cookieString componentsSeparatedByString:@";"];
    for (NSInteger i = 0; i < segements.count; i++) {
        NSString *seg = segements[i];
        NSString *trimSeg = [seg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray<NSString *> *keyWithValues = [trimSeg componentsSeparatedByString:@"="];
        if (keyWithValues.count == 2 && keyWithValues[0].length > 0) {
            NSString *trimKey = [keyWithValues[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *trimValue = [keyWithValues[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            if (i == 0) {
                properties[NSHTTPCookieName] = trimKey;
                properties[NSHTTPCookieValue] = trimValue;
            } else if ([trimKey isEqualToString:@"domain"]) {
                properties[NSHTTPCookieDomain] = trimValue;
            } else if ([trimKey isEqualToString:@"path"]) {
                properties[NSHTTPCookiePath] = trimValue;
            } else if ([trimKey isEqualToString:@"expires"] && trimValue.length > 0) {
                properties[NSHTTPCookieExpires] = [[KKWebViewCookieManager cookieDateFormatter] dateFromString:trimValue];;
            } else {
                // 虽然设置可能也不会生效，但是在这里做个兜底。因为必须设置 NSHTTPCookieName 这样的常量作为键，NSHTTPCookie 才能识别。
                properties[trimKey] = trimValue;
            }
        } else if (keyWithValues.count == 1 && keyWithValues[0].length > 0) {// 说明是单个 key 的属性
            NSString *trimKey = [keyWithValues[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([trimKey isEqualToString:@"Secure"]) {
                properties[NSHTTPCookieSecure] = @(YES);
            } else {
                // 虽然 NSHTTPCookie 不支持 HTTPOnly 属性设置，还是做个兜底设置，虽然可能也不会生效。
                properties[trimKey] = @(YES);
            }
        }
    }
    
    if (properties.count > 0) {
        NSHTTPCookie *cookieObject = [NSHTTPCookie cookieWithProperties:properties];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookieObject];
    }
}

/**
Hook cookie 读取操作，把 NSHTTPCookieStorage cookie 返回给 H5

比如：
H5 控制台执行如下语句
> document.cookie
> qq=55x; name=66y;

*/
- (void)cookie:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    NSString *url = params[@"url"];
    if (!url) {
        responseCallback ? responseCallback(@{@"cookie": @""}) : nil;
        return;
    }
    
    NSArray<NSHTTPCookie *> *availableCookie = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:url]];
    if (availableCookie.count > 0) {
        NSDictionary *reqHeader = [NSHTTPCookie requestHeaderFieldsWithCookies:availableCookie];
        NSString *cookieStr = [reqHeader objectForKey:@"Cookie"];
        responseCallback ? responseCallback(@{@"cookie": cookieStr ? cookieStr : @""}) : nil;
    } else {
        responseCallback ? responseCallback(@{@"cookie": @""}) : nil;
    }
}

@end
