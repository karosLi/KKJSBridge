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
    
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:[NSString stringWithFormat:@"window.KKJSBridgeConfig.enableAjaxHook(%@)", [NSNumber numberWithBool:enableAjaxHook]] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [self.engine.webView.configuration.userContentController addUserScript:userScript];
}

@end

