//
//  KKJSBridgeWeakScriptMessageDelegate.m
//  KKJSBridge
//
//  Created by karos li on 2019/7/23.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "KKJSBridgeWeakScriptMessageDelegate.h"

@interface KKJSBridgeWeakScriptMessageDelegate()

@property (nonatomic, weak, readwrite) id<WKScriptMessageHandler> scriptDelegate;

@end

@implementation KKJSBridgeWeakScriptMessageDelegate

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate {
    self = [super init];
    if (self) {
        _scriptDelegate = scriptDelegate;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.scriptDelegate userContentController:userContentController didReceiveScriptMessage:message];
}

@end
