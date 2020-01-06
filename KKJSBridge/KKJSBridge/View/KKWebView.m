//
//  KKWebView.m
//  KKJSBridge
//
//  Created by karos li on 2019/7/29.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "KKWebView.h"
#import "KKWebViewPool.h"
#import "WKWebView+KKWebViewReusable.h"
#import "KKWebViewCookieManager.h"

@interface KKWebView() <WKNavigationDelegate, WKUIDelegate>

/// A real delegate of the class.
@property (nonatomic, weak) id<WKNavigationDelegate> realNavigationDelegate;

@end

@implementation KKWebView

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    // 虽然传入 nil 会有警告，这里还是做一层判断
    if (!configuration) {
        configuration = [WKWebViewConfiguration new];
    }
    
    if (self = [super initWithFrame:frame configuration:configuration]) {
        if (!self.configuration.userContentController) {
            self.configuration.userContentController = [WKUserContentController new];
        }
        
        self.configuration.processPool = [KKWebView processPool];
        self.navigationDelegate = self;
        self.UIDelegate = self;
    }
    
    return self;
}

#pragma mark - cookie
/**
 【COOKIE 1】同步首次请求的 cookie
 */
- (nullable WKNavigation *)loadRequest:(NSURLRequest *)request {
    if (request.URL.scheme.length > 0) {
        [self syncAjaxCookie];
        NSMutableURLRequest *requestWithCookie = request.mutableCopy;
        [KKWebViewCookieManager syncRequestCookie:requestWithCookie];
        return [super loadRequest:requestWithCookie];
    }
    
    return [super loadRequest:request];
}

/**
 【COOKIE 2】为异步 ajax 请求同步 cookie
 */
- (void)syncAjaxCookie {
    WKUserScript *cookieScript = [[WKUserScript alloc] initWithSource:[KKWebViewCookieManager ajaxCookieScripts] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [self.configuration.userContentController addUserScript:cookieScript];
}

#pragma mark - WKNavigationDelegate

// 1、在发送请求之前，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    /**
     【COOKIE 3】对服务器端重定向(302)/浏览器重定向(a标签[包括 target="_blank"]) 进行同步 cookie 处理。
     由于所有的跳转都会是 NSMutableURLRequest 类型，同时也无法单独区分出 302 服务器端重定向跳转，所以这里统一对服务器端重定向(302)/浏览器重定向(a标签[包括 target="_blank"])进行同步 cookie 处理。
     */
    if ([navigationAction.request isKindOfClass:NSMutableURLRequest.class]) {
        [KKWebViewCookieManager syncRequestCookie:(NSMutableURLRequest *)navigationAction.request];
    }

    id<WKNavigationDelegate> mainDelegate = self.realNavigationDelegate;
    if ([mainDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        [mainDelegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

// 2、在收到响应后，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    // iOS 12 之后，响应头里 Set-Cookie 不再返回。 所以这里针对系统版本做区分处理。
    if (@available(iOS 11.0, *)) {
        // 【COOKIE 4】同步 WKWebView cookie 到 NSHTTPCookieStorage。
        [KKWebViewCookieManager copyWKHTTPCookieStoreToNSHTTPCookieStorageForWebViewOniOS11:webView withCompletion:nil];
    } else {
        // 【COOKIE 4】同步服务器端响应头里的 Set-Cookie，既把 WKWebView cookie 同步到 NSHTTPCookieStorage。
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)navigationResponse.response;
        NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:response.URL];
        for (NSHTTPCookie *cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
    }
    
    id<WKNavigationDelegate> mainDelegate = self.realNavigationDelegate;
    if ([mainDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationResponse:decisionHandler:)]) {
        [mainDelegate webView:webView decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
    } else {
        decisionHandler(WKNavigationResponsePolicyAllow);
    }
}

// 3、页面跳转完成时调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    id<WKNavigationDelegate> mainDelegate = self.realNavigationDelegate;
    
    if ([mainDelegate respondsToSelector:@selector(webView:didFinishNavigation:)]) {
        [mainDelegate webView:webView didFinishNavigation:navigation];
    }
    
    // 预加载下一个 WebView
    [self prepareNextWebViewIfNeed];
}

// 4、需要校验服务器可信度时调用
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
    id<WKNavigationDelegate> mainDelegate = self.realNavigationDelegate;
    if ([mainDelegate respondsToSelector:@selector(webView:didReceiveAuthenticationChallenge:completionHandler:)]) {
        [mainDelegate webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

#pragma mark - WKUIDelegate
// 创建一个新的 webView
- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (!navigationAction.targetFrame.isMainFrame) {// 针对 <a target="_blank" href="" > 做处理。同时也会同步 cookie， 保持 loadRequest 加载请求携带 cookie 的一致性。
        [webView loadRequest:[KKWebViewCookieManager fixRequest:navigationAction.request]];
    }
    return nil;
}

// webView 中的提示弹窗
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    if (![self canShowPanelWithWebView:webView]) {
        completionHandler();
        return;
    }
    
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:@"" message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *_Nonnull action) {
                                                           completionHandler();
                                                       }])];
    
    UIViewController *topPresentedViewController = [self _topPresentedViewController];
    if (topPresentedViewController.presentingViewController) {
        completionHandler();
    } else {
        [topPresentedViewController presentViewController:alertController animated:YES completion:nil];
    }
}

// webView 中的确认弹窗
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    if (![self canShowPanelWithWebView:webView]) {
        completionHandler(NO);
        return;
    }
    
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:@"" message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消"
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction *_Nonnull action) {
                                                           completionHandler(NO);
                                                       }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确定"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *_Nonnull action) {
                                                           completionHandler(YES);
                                                       }])];
    
    UIViewController *topPresentedViewController = [self _topPresentedViewController];
    if (topPresentedViewController.presentingViewController) {
        completionHandler(NO);
    } else {
        [topPresentedViewController presentViewController:alertController animated:YES completion:nil];
    }
}

// webView 中的输入框
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler {
    if (![self canShowPanelWithWebView:webView]) {
        completionHandler(nil);
        return;
    }
    
    NSString *hostString = webView.URL.host;
    NSString *sender = [NSString stringWithFormat:@"%@", hostString];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt
                                                                             message:sender
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = defaultText;
    }];
    [alertController
     addAction:([UIAlertAction actionWithTitle:@"确定"
                                         style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action) {
                                           if (alertController.textFields && alertController.textFields.count > 0) {
                                               UITextField *textFiled = [alertController.textFields firstObject];
                                               if (textFiled.text && textFiled.text.length > 0) {
                                                   completionHandler(textFiled.text);
                                               } else {
                                                   completionHandler(nil);
                                               }
                                           } else {
                                               completionHandler(nil);
                                           }
                                       }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消"
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction *action) {
                                                           completionHandler(nil);
                                                       }])];
    
    UIViewController *topPresentedViewController = [self _topPresentedViewController];
    if (topPresentedViewController.presentingViewController) {
        completionHandler(nil);
    } else {
        [topPresentedViewController presentViewController:alertController animated:YES completion:nil];
    }
}

- (BOOL)canShowPanelWithWebView:(WKWebView *)webView {
    if ([webView.holderObject isKindOfClass:[UIViewController class]]) {
        UIViewController *vc = (UIViewController *)webView.holderObject;
        if (vc.isBeingPresented || vc.isBeingDismissed || vc.isMovingToParentViewController || vc.isMovingFromParentViewController) {
            return NO;
        }
    }
    return YES;
}

- (UIViewController *)_topPresentedViewController {
    UIViewController *viewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    while (viewController.presentedViewController)
        viewController = viewController.presentedViewController;
    return viewController;
}

#pragma mark - 当前 WebView 加载完时，先预加载下一个 WebView 实例，以备下个页面可以直接使用
- (void)prepareNextWebViewIfNeed {
    // 只有当 WebViewPool 里包含 WebView class 类型，说明当前 WebView 是通过 WebViewPool 创建出来的，此时才需要预加载下一个 WebView 实例
    if ([[KKWebViewPool sharedInstance] containsReusableWebViewWithClass:self.class]) {
        [[KKWebViewPool sharedInstance] enqueueWebViewWithClass:self.class];
    }
}


#pragma mark -
#pragma mark WKNavigationDelegate Forwarder

- (void)setNavigationDelegate:(id<WKNavigationDelegate>)navigationDelegate
{
    self.realNavigationDelegate = (navigationDelegate != self ? navigationDelegate : nil);
    super.navigationDelegate = navigationDelegate ? self : nil;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [super respondsToSelector:aSelector] || [_realNavigationDelegate respondsToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [super methodSignatureForSelector:aSelector] ?: [(id)_realNavigationDelegate methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    id delegate = _realNavigationDelegate;
    if ([delegate respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:delegate];
    }
}


#pragma mark - process
/**
 通过让所有 WKWebView 共享同一个WKProcessPool实例，可以实现多个 WKWebView 之间共享 Cookie（session Cookie and persistent Cookie）数据。Session Cookie（代指没有设置 expires 的 cookie），Persistent Cookie （设置了 expires 的 cookie）。
 
 另外 WKWebView WKProcessPool 实例在 app 杀进程重启后会被重置，导致 WKProcessPool 中的 session Cookie 数据丢失。
 同样的，如果是存储在 NSHTTPCookieStorage 里面的 SeesionOnly cookie 也会在 app 杀掉进程后清空。
 
 @return processPool
 */
+ (WKProcessPool *)processPool {
    static WKProcessPool *pool;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pool = [[WKProcessPool alloc] init];
    });
    
    return pool;
}

@end
