# KKJSBridge

一站式解决 WKWebView 支持离线包，Ajax 请求和 Cookie 同步的问题 (基于 Ajax Hook 和 Cookie Hook)

[更详细的介绍](http://karosli.com/2019/08/30/%E4%B8%80%E7%AB%99%E5%BC%8F%E8%A7%A3%E5%86%B3WKWebView%E5%90%84%E7%B1%BB%E9%97%AE%E9%A2%98/)

## KKJSBridge 支持的功能

- 基于 MessageHandler 搭建通信层

- 支持模块化的管理 JSAPI

- 支持模块共享上下文信息

- 支持模块消息转发

- 支持离线资源

- 支持 ajax hook 避免 body 丢失

- Native 侧控制 ajax hook

- 支持表单数据，支持图片上传（表单虽好，可不要依赖哈）

- 支持 ajax 请求外部代理

- Cookie 统一管理

- WKWebView 复用

- 兼容 WebViewJavascriptBridge

## Demo

模块化调用 JSAPI

![模块化调用 JSAPI](https://github.com/karosLi/KKJSBridge/blob/master/Demo1.gif)

ajax hook 演示

![ajax hook 演示](https://github.com/karosLi/KKJSBridge/blob/master/Demo2.gif)

淘宝 ajax hook 演示

![淘宝 ajax hook 演示](https://github.com/karosLi/KKJSBridge/blob/master/Demo3.gif)

ajax 发送表单 演示
![淘宝 ajax hook 演示](https://github.com/karosLi/KKJSBridge/blob/master/Demo4.gif)

## 用法

从复用池取出缓存的 WKWebView，并开启 ajax hook

```objectivec
+ (void)load {
    __block id observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [self prepareWebView];
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }];
}

+ (void)prepareWebView {
    // 预先缓存一个 webView
    [KKWebView configCustomUAWithType:KKWebViewConfigUATypeAppend UAString:@"KKJSBridge/1.0.0"];
    [[KKWebViewPool sharedInstance] makeWebViewConfiguration:^(WKWebViewConfiguration * _Nonnull configuration) {
        // 必须前置配置，否则会造成属性不生效的问题
        configuration.allowsInlineMediaPlayback = YES;
        configuration.preferences.minimumFontSize = 12;
    }];
    [[KKWebViewPool sharedInstance] enqueueWebViewWithClass:KKWebView.class];
}

- (void)dealloc {
    // 回收到复用池
    [[KKWebViewPool sharedInstance] enqueueWebView:self.webView];
}

- (void)commonInit {
    _webView = [[KKWebViewPool sharedInstance] dequeueWebViewWithClass:KKWebView.class webViewHolder:self];
    _webView.configuration.allowsInlineMediaPlayback = YES;
    _webView.configuration.preferences.minimumFontSize = 12;
    _webView.hybirdDelegate = self;
    _jsBridgeEngine = [KKJSBridgeEngine bridgeForWebView:self.webView];
    _jsBridgeEngine.config.enableAjaxHook = YES; // 开启 ajax hook
    _jsBridgeEngine.config.ajaxDelegateManager = self; // 请求外部代理处理，可以借助 AFN 网络库来发送请求

    [self registerModule];
}

#pragma mark - KKJSBridgeAjaxDelegateManager
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request callbackDelegate:(NSObject<KKJSBridgeAjaxDelegate> *)callbackDelegate {
    // 使用 AFN 发送 ajax 请求 
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manage = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    return [manage dataTaskWithRequest:request uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
        [callbackDelegate JSBridgeAjaxInProcessing:callbackDelegate];
    } downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
        [callbackDelegate JSBridgeAjaxInProcessing:callbackDelegate];
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        [callbackDelegate JSBridgeAjaxDidCompletion:callbackDelegate response:response responseObject:responseObject error:error];
    }];
}
```

注册模块

```objectivec
- (void)registerModule {
 ModuleContext *context = [ModuleContext new];
 context.vc = self;
 context.scrollView = self.webView.scrollView;
 context.name = @"上下文";
 // 注册 默认模块
 [self.jsBridgeEngine.moduleRegister registerModuleClass:ModuleDefault.class];
 // 注册 模块A
 [self.jsBridgeEngine.moduleRegister registerModuleClass:ModuleA.class];
 // 注册 模块B 并带入上下文
 [self.jsBridgeEngine.moduleRegister registerModuleClass:ModuleB.class withContext:context];
 // 注册 模块C
 [self.jsBridgeEngine.moduleRegister registerModuleClass:ModuleC.class];
}
```

模块定义

```objectivec
@interface ModuleB()<KKJSBridgeModule>

@property (nonatomic, weak) ModuleContext *context;

@end

@implementation ModuleB

// 模块名称
+ (nonnull NSString *)moduleName {
    return @"b";
}

// 单例模块
+ (BOOL)isSingleton {
    return YES;
}

// 模块初始化方法，支持上下文带入
- (instancetype)initWithEngine:(KKJSBridgeEngine *)engine context:(id)context {
    if (self = [super init]) {
        _context = context;
        NSLog(@"ModuleB 初始化并带上 %@", self.context.name);
    }

    return self;
}

// 模块提供的方法
- (void)callToGetVCTitle:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    responseCallback ? responseCallback(@{@"title": self.context.vc.navigationItem.title ? self.context.vc.navigationItem.title : @""}) : nil;
}
```

JS 侧调用方式

```javascript
window.KKJSBridge.call('b', 'callToGetVCTitle', {}, function(res) {
    console.log('receive vc title：', res.title);
});
```



## 安装

1. CocoaPods
   
   ```objectivec
   //In Podfile
   pod "KKJSBridge"
   ```
   
## 更新历史
### 2020.5.18
- 支持通过 off 方法取消事件监听
### 2020.3.3
- 回收 webView 到复用池时，清除 sessionStorage
- 支持 on 事件广播，让 H5 可以在多个地方注册事件监听
### 2019.10.23
- 提供统一配置 configuration 方法，有些属性必须前置配置，否则会不生效
### 2019.10.22
- 增加模块注册支持首次初始化

### 2019.9.29
- 仅保留 Native 侧控制 ajax hook，主要是避免 ajax hook 时机不对时，会造成首次 hook 失败
- 支持表单数据，支持图片上传
- 支持 ajax 请求外部代理

## TODO

- [ ] Fetch hook。 虽然现在大多数 H5 页面的异步请求都是基于 ajax 实现的，随着 Fetch 的慢慢普及，后面也会多起来。

## 参考

- [Ajax-hook](https://github.com/wendux/Ajax-hook)

- [HybridPageKit](https://github.com/dequan1331/HybridPageKit)

- [kerkee_ios](https://github.com/kercer/kerkee_ios)


