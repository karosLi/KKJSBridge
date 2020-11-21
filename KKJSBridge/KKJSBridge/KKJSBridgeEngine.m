//
//  KKJSBridgeEngine.m
//  KKJSBridge
//
//  Created by karos li on 2019/7/19.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "KKJSBridgeEngine.h"
#import "KKJSBridgeMessageDispatcher.h"
#import "KKJSBridgeMessage.h"
#import "KKJSBridgeModuleCookie.h"
#import "KKJSBridgeWeakScriptMessageDelegate.h"
#import "WKWebView+KKJSBridgeEngine.h"

static NSString * const KKJSBridgeMessageName = @"KKJSBridgeMessage";

@interface KKJSBridgeEngine()<WKScriptMessageHandler>

@property (nonatomic, weak, readwrite) WKWebView *webView;
@property (nonatomic, strong, readwrite) KKJSBridgeModuleRegister *moduleRegister; // 模块注册者
@property (nonatomic, strong, readwrite) KKJSBridgeMessageDispatcher *dispatcher; // 消息分发者
@property (nonatomic, strong, readwrite) KKJSBridgeConfig *config; // jsbridge 配置
@end

@implementation KKJSBridgeEngine

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"KKJSBridgeEngine dealloc");
#endif
    
    WKWebView *webView = (WKWebView *)self.webView;
    [webView.configuration.userContentController removeScriptMessageHandlerForName:KKJSBridgeMessageName];
}

+ (instancetype)bridgeForWebView:(WKWebView *)webView {
    KKJSBridgeEngine *bridge = [[self alloc] initWithWebView:webView];
    webView.kk_engine = bridge;
    return bridge;
}

- (void)dispatchEvent:(NSString *)eventName data:(NSDictionary * _Nullable)data {
    [self.dispatcher dispatchEventMessage:eventName data:data];
}

- (void)dispatchCall:(NSString *)module method:(NSString *)method data:(NSDictionary * _Nullable)data callback:(void (^)(NSDictionary * _Nullable responseData))callback {
    KKJSBridgeMessage *message = [KKJSBridgeMessage new];
    message.module = module;
    message.method = method;
    message.data = data;
    message.callback = callback;
    
    [self.dispatcher dispatchCallbackMessage:message];
}

- (instancetype)initWithWebView:(WKWebView *)webView {
    if (self = [super init]) {
        _webView = webView;
        [self commonInit];
        [self setup];
    }
    
    return self;
}

- (void)commonInit {
    _moduleRegister = [[KKJSBridgeModuleRegister alloc] initWithEngine:self];
    _dispatcher = [[KKJSBridgeMessageDispatcher alloc] initWithEngine:self];
    _config = [[KKJSBridgeConfig alloc] initWithEngine:self];// 用于记录外部配置
}

#pragma mark - 安装
- (void)setup {
    [self setupJSBridge];
    [self setupDefaultModuleRegister];
}

- (void)setupJSBridge {
    WKWebViewConfiguration *webViewConfiguration = self.webView.configuration;
    if (webViewConfiguration && !webViewConfiguration.userContentController) {
        self.webView.configuration.userContentController = [WKUserContentController new];
    }
    
    NSString *bridgeJSName = @"KKJSBridgeAJAXProtocolHook";
#ifdef KKAjaxProtocolHook
    bridgeJSName = @"KKJSBridgeAJAXProtocolHook";
#else
    bridgeJSName = @"KKJSBridgeAJAXHook";
#endif

    NSString *bridgeJSString = [[NSString alloc] initWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:bridgeJSName ofType:@"js"] encoding:NSUTF8StringEncoding error:NULL];
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:bridgeJSString injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:KKJSBridgeMessageName];
    [self.webView.configuration.userContentController addUserScript:userScript];
    // 防止内存泄露
    [self.webView.configuration.userContentController addScriptMessageHandler:[[KKJSBridgeWeakScriptMessageDelegate alloc] initWithDelegate:self] name:KKJSBridgeMessageName];
}

- (void)setupDefaultModuleRegister {
#ifdef KKAjaxProtocolHook
    [self.moduleRegister registerModuleClass:NSClassFromString(@"KKJSBridgeXMLBodyCacheRequest")];
#else
    [self.moduleRegister registerModuleClass:NSClassFromString(@"KKJSBridgeModuleXMLHttpRequestDispatcher")];
#endif
    [self.moduleRegister registerModuleClass:KKJSBridgeModuleCookie.class];
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:KKJSBridgeMessageName]) {
        NSMutableDictionary *messageJson = [[NSMutableDictionary alloc] initWithDictionary:message.body];
        KKJSBridgeMessage *messageInstance = [self.dispatcher convertMessageFromMessageJson:messageJson];
        [self.dispatcher dispatchCallbackMessage:messageInstance];
    }
}

@end
