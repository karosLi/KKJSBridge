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
#import "NSURLProtocol+KKJSBridgeWKWebView.h"

static id<KKJSBridgeAjaxDelegateManager> globalAjaxDelegateManager;

@interface KKJSBridgeConfig()

@property (nonatomic, weak) KKJSBridgeEngine *engine;

@end

@implementation KKJSBridgeConfig

- (instancetype)initWithEngine:(KKJSBridgeEngine *)engine {
    if (self = [super init]) {
        _engine = engine;
    }
    
    return self;
}

- (void)setEnableAjaxHook:(BOOL)enableAjaxHook {
    _enableAjaxHook = enableAjaxHook;
    
    if (enableAjaxHook) {
        [NSURLProtocol KKJSBridgeRegisterScheme:@"https"];
        [NSURLProtocol KKJSBridgeRegisterScheme:@"http"];
    } else {
        [NSURLProtocol KKJSBridgeUnregisterScheme:@"https"];
        [NSURLProtocol KKJSBridgeUnregisterScheme:@"http"];
    }
    
    NSString *script = [NSString stringWithFormat:@"window.KKJSBridgeConfig.enableAjaxHook(%@)", [NSNumber numberWithBool:enableAjaxHook]];
    if (self.engine.isBridgeReady) {
        [KKJSBridgeJSExecutor evaluateJavaScript:script inWebView:self.engine.webView completionHandler:nil];
    } else {
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:script injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        [self.engine.webView.configuration.userContentController addUserScript:userScript];
    }
}

+ (void)setAjaxDelegateManager:(id<KKJSBridgeAjaxDelegateManager>)ajaxDelegateManager {
    globalAjaxDelegateManager = ajaxDelegateManager;
}

+ (id<KKJSBridgeAjaxDelegateManager>)ajaxDelegateManager {
    return globalAjaxDelegateManager;
}

@end

