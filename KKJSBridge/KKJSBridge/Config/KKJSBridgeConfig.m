//
//  KKJSBridgeConfig.m
//  KKJSBridge
//
//  Created by karos li on 2019/7/25.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "KKJSBridgeConfig.h"
#import "KKJSBridgeJSExecutor.h"
#import "KKJSBridgeEngine.h"

#ifdef KKAjaxProtocolHook
#import "NSURLProtocol+KKJSBridgeWKWebView.h"
#endif

static id<KKJSBridgeAjaxDelegateManager> globalAjaxDelegateManager;

@interface KKJSBridgeConfig()

@property (nonatomic, weak) KKJSBridgeEngine *engine;

@end

@implementation KKJSBridgeConfig

- (instancetype)initWithEngine:(KKJSBridgeEngine *)engine {
    if (self = [super init]) {
        _engine = engine;
        _enableCookieSetHook = YES;
        _enableCookieGetHook = YES;
    }
    
    return self;
}

#pragma mark - public
- (void)setEnableAjaxHook:(BOOL)enableAjaxHook {
    _enableAjaxHook = enableAjaxHook;
    
#ifdef KKAjaxProtocolHook
    if (enableAjaxHook) {
        [NSURLProtocol KKJSBridgeRegisterScheme:@"https"];
        [NSURLProtocol KKJSBridgeRegisterScheme:@"http"];
    } else {
        [NSURLProtocol KKJSBridgeUnregisterScheme:@"https"];
        [NSURLProtocol KKJSBridgeUnregisterScheme:@"http"];
    }
#endif
    
    NSString *script = [NSString stringWithFormat:@"window.KKJSBridgeConfig.enableAjaxHook(%@)", [NSNumber numberWithBool:enableAjaxHook]];
    [self evaluateConfigScript:script];
}

- (void)setEnableCookieSetHook:(BOOL)enableCookieSetHook {
    _enableCookieSetHook = enableCookieSetHook;
    
    NSString *script = [NSString stringWithFormat:@"window.KKJSBridgeConfig.enableCookieSetHook(%@)", [NSNumber numberWithBool:enableCookieSetHook]];
    [self evaluateConfigScript:script];
}

- (void)setEnableCookieGetHook:(BOOL)enableCookieGetHook {
    _enableCookieGetHook = enableCookieGetHook;
    
    NSString *script = [NSString stringWithFormat:@"window.KKJSBridgeConfig.enableCookieGetHook(%@)", [NSNumber numberWithBool:enableCookieGetHook]];
    [self evaluateConfigScript:script];
}

#pragma mark - public static
+ (void)setAjaxDelegateManager:(id<KKJSBridgeAjaxDelegateManager>)ajaxDelegateManager {
    globalAjaxDelegateManager = ajaxDelegateManager;
}

+ (id<KKJSBridgeAjaxDelegateManager>)ajaxDelegateManager {
    return globalAjaxDelegateManager;
}

#pragma mark - private
- (void)evaluateConfigScript:(NSString *)script {
    if (self.engine.isBridgeReady) {
        [KKJSBridgeJSExecutor evaluateJavaScript:script inWebView:self.engine.webView completionHandler:nil];
    } else {
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:script injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        [self.engine.webView.configuration.userContentController addUserScript:userScript];
    }
}

@end

