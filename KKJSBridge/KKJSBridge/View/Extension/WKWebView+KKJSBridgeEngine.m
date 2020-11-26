//
//  WKWebView+KKJSBridgeEngine.m
//  KKJSBridge
//
//  Created by karos li on 2020/11/20.
//  Copyright © 2020 karosli. All rights reserved.
//

#import "WKWebView+KKJSBridgeEngine.h"
#import <objc/runtime.h>
#import "KKJSBridgeEngine.h"
#import "KKJSBridgeWeakProxy.h"

@implementation WKWebView (KKJSBridgeEngine)

- (KKJSBridgeEngine *)kk_engine {
    KKJSBridgeWeakProxy *proxy = objc_getAssociatedObject(self, @selector(kk_engine));
    return proxy.target;
}

- (void)setKk_engine:(KKJSBridgeEngine *)kk_engine {
    KKJSBridgeWeakProxy *proxy = [KKJSBridgeWeakProxy proxyWithTarget:kk_engine];
    objc_setAssociatedObject(self, @selector(kk_engine), proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - 处理 prompt 同步 JS 调用
- (BOOL)handleSyncCallWithPrompt:(NSString * _Nullable)prompt defaultText:(NSString * _Nullable)defaultText completionHandler:(void (^)(NSString * _Nullable result))completionHandler {
    if (![prompt isEqualToString:@"KKJSBridge"]) {
        return NO;
    }

    if (!defaultText || !self.kk_engine) {
        completionHandler ? completionHandler(nil) : nil;
        return YES;
    }

    NSData *jsonData = [defaultText dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *body = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
    if (!body) {
        completionHandler ? completionHandler(nil) : nil;
        return YES;
    }
    
    NSString *module = body[@"module"];
    NSString *method = body[@"method"];
    NSDictionary *data = body[@"data"];
    [self.kk_engine dispatchCall:module method:method data:data callback:^(NSDictionary * _Nullable responseData) {
        if (nil == completionHandler) {
            return;
        }
        
        if (nil == responseData || 0 == responseData.count) {
            return completionHandler(nil);
        }
        
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:responseData options:kNilOptions error:&error];
        if (nil != error || nil == jsonData) {
            return completionHandler(nil);
        }
        
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        completionHandler(jsonString);
    }];
    
    return YES;
}

@end
