//
//  NSURLProtocol+KKJSBridgeWKWebView.m
//  KKJSBridge
//
//  Created by karos li on 2020/6/20.
//

#import "NSURLProtocol+KKJSBridgeWKWebView.h"
#import <WebKit/WebKit.h>

// https://github.com/WebKit/webkit/blob/989f1ffc97f6b168687cbfc6f98d35880fdd29de/Source/WebKit/UIProcess/API/Cocoa/WKBrowsingContextController.mm
Class KKJSBridge_WKWebView_ContextControllerClass() {
    static Class cls;
    if (!cls) {
        if (@available(iOS 8.0, *)) {
            cls = [[[WKWebView new] valueForKey:@"browsingContextController"] class];
        } else {
            
        }
    }
    return cls;
}
//customSchemes
SEL KKJSBridge_WKWebView_RegisterSchemeSelector() {
    return NSSelectorFromString(@"registerSchemeForCustomProtocol:");
}

SEL KKJSBridge_WKWebView_UnregisterSchemeSelector() {
    return NSSelectorFromString(@"unregisterSchemeForCustomProtocol:");
}

@implementation NSURLProtocol (KKJSBridgeWKWebView)

+ (void)KKJSBridgeRegisterScheme:(NSString *)scheme {
    Class cls = KKJSBridge_WKWebView_ContextControllerClass();
    SEL sel = KKJSBridge_WKWebView_RegisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
    }
}

+ (void)KKJSBridgeUnregisterScheme:(NSString *)scheme {
    Class cls = KKJSBridge_WKWebView_ContextControllerClass();
    SEL sel = KKJSBridge_WKWebView_UnregisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
    }
}


@end
