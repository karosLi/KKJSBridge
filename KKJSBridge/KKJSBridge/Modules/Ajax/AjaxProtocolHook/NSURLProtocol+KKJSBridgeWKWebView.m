//
//  NSURLProtocol+KKJSBridgeWKWebView.m
//  KKJSBridge
//
//  Created by karos li on 2020/6/20.
//

#import "NSURLProtocol+KKJSBridgeWKWebView.h"
#import <WebKit/WebKit.h>

// https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/API/Cocoa/WKBrowsingContextController.mm
static Class KKJSBridge_WKWebView_ContextControllerClass(void) {
    static Class cls;
    if (!cls) {
        if (@available(iOS 8.0, *)) {
            cls = [[[WKWebView new] valueForKey:@"browsingContextController"] class];
        }
    }
    return cls;
}
//customSchemes
static SEL KKJSBridge_WKWebView_RegisterSchemeSelector(void) {
    return NSSelectorFromString(@"registerSchemeForCustomProtocol:");
}

static SEL KKJSBridge_WKWebView_UnregisterSchemeSelector(void) {
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
