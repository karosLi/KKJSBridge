# KKJSBridge

[![GitHub stars](https://img.shields.io/github/stars/karosLi/KKJSBridge)](https://github.com/karosLi/KKJSBridge/stargazers) [![GitHub forks](https://img.shields.io/github/forks/karosLi/KKJSBridge)](https://github.com/karosLi/KKJSBridge/network) [![GitHub issues](https://img.shields.io/github/issues/karosLi/KKJSBridge)](https://github.com/karosLi/KKJSBridge/issues) [![GitHub license](https://img.shields.io/github/license/karosLi/KKJSBridge)](https://github.com/karosLi/KKJSBridge/blob/master/LICENSE)

一站式解决 WKWebView 支持离线包，Ajax/Fetch 请求和 Cookie 同步的问题 (基于 Ajax Hook，Fetch Hook 和 Cookie Hook)

[更详细的介绍](http://karosli.com/2019/08/30/%E4%B8%80%E7%AB%99%E5%BC%8F%E8%A7%A3%E5%86%B3WKWebView%E5%90%84%E7%B1%BB%E9%97%AE%E9%A2%98/)

## KKJSBridge 支持的功能
- JSBrdige 相关

    - 基于 MessageHandler 搭建通信层

    - 支持模块化的管理 JSAPI

    - 支持模块共享上下文信息

    - 支持模块消息转发

    - 支持 JSBridge 同步调用
    
    - 兼容 WebViewJavascriptBridge

- 请求相关

    - 支持离线资源

    - 支持 ajax/fetch hook 避免 body 丢失
    
    - 支持 ajax/fetch 同步请求

    - Native 侧控制 ajax/fetch hook

    - 支持表单数据，支持图片上传

    - 支持 ajax/fetch 请求外部代理
    
    - 分别提供了 ajax hook 和 ajax urlprotocol hook 两种方案，可以根据具体需求自由选择
     

- WebView 相关

    - Cookie 统一管理

    - WKWebView 复用



## Demo
### demo 概览

![模块化调用 JSAPI](https://github.com/karosLi/KKJSBridge/blob/master/Demo0.gif)

### 模块化调用 JSAPI

![模块化调用 JSAPI](https://github.com/karosLi/KKJSBridge/blob/master/Demo1.gif)

### ajax hook 演示

![ajax hook 演示](https://github.com/karosLi/KKJSBridge/blob/master/Demo2.gif)

### 淘宝 ajax hook 演示

![淘宝 ajax hook 演示](https://github.com/karosLi/KKJSBridge/blob/master/Demo3.gif)

### ajax 发送表单 演示
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
    KKJSBridgeConfig.ajaxDelegateManager = (id<KKJSBridgeAjaxDelegateManager>)self; // 请求外部代理处理，可以借助 AFN 网络库来发送请求
}

- (void)dealloc {
    // 回收到复用池
    [[KKWebViewPool sharedInstance] enqueueWebView:self.webView];
}

- (void)commonInit {
    _webView = [[KKWebViewPool sharedInstance] dequeueWebViewWithClass:KKWebView.class webViewHolder:self];
    _webView.navigationDelegate = self;
    _jsBridgeEngine = [KKJSBridgeEngine bridgeForWebView:self.webView];
    _jsBridgeEngine.config.enableAjaxHook = YES; // 开启 ajax hook

    [self registerModule];
}

#pragma mark - KKJSBridgeAjaxDelegateManager
+ (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request callbackDelegate:(NSObject<KKJSBridgeAjaxDelegate> *)callbackDelegate {
    return [[self ajaxSesstionManager] dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        // 处理响应数据
        [callbackDelegate JSBridgeAjax:callbackDelegate didReceiveResponse:response];
        if ([responseObject isKindOfClass:NSData.class]) {
            [callbackDelegate JSBridgeAjax:callbackDelegate didReceiveData:responseObject];
        } else if ([responseObject isKindOfClass:NSDictionary.class]) {
            NSData *responseData = [NSJSONSerialization dataWithJSONObject:responseObject options:0 error:nil];
            [callbackDelegate JSBridgeAjax:callbackDelegate didReceiveData:responseData];
        } else {
            NSData *responseData = [NSJSONSerialization dataWithJSONObject:@{} options:0 error:nil];
            [callbackDelegate JSBridgeAjax:callbackDelegate didReceiveData:responseData];
        }
        [callbackDelegate JSBridgeAjax:callbackDelegate didCompleteWithError:error];
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
// 异步调用
window.KKJSBridge.call('b', 'callToGetVCTitle', {}, function(res) {
    console.log('receive vc title：', res.title);
});

// 同步调用
var res = window.KKJSBridge.syncCall('b', 'callToGetVCTitle', {});
console.log('receive vc title：', res.title);
```



## 安装

1. CocoaPods
   
   ```objectivec
   //In Podfile
   
   # 分别提供了 ajax hook 和 ajax urlprotocol hook 两种方案，可以根据具体需求自由选择。
   # 只能选择其中一个方案，默认是 ajax protocol hook。
   pod 'KKJSBridge/AjaxProtocolHook'
   pod 'KKJSBridge/AjaxHook'

   ```
  
## Ajax Hook 方案对比

这里只对比方案间相互比较的优缺点，共同的优点，就不赘述了。如果对私有 API 不敏感的，我是比较推荐使用方案一的。

### 方案一：Ajax Hook 部分 API + NSURLProtocol 
这个方案对应的是这里的 `KKJSBridge/AjaxProtocolHook`。

原理介绍：此种方案，是只需要 hook ajax 中的 open/send 方法，在 hook 的 send 方法里，先把要发送的 body 通过 JSBridge 发送到 Native 侧去缓存起来。缓存成功后，再去执行真实的 send 方法，NSURLProtocol 此时会拦截到该请求，然后取出之前缓存的 body 数据，重新拼接请求，就可以发送出去了，然后通过 NSURLProtocol 把请求结果返回给 WebView 内核。

优点：

- 兼容性会更好，网络请求都是走 webview 原生的方式。
- hook 的逻辑会更少，会更加稳定。
- 可以更好的支持 ajax 获取二进制的数据。例如 H5 小游戏场景（白鹭引擎是通过异步获取图片资源）。

缺点：

- 需要使用到私有 API browsingContextController 去注册 http/https。（其实现在大部分的离线包方案也是使用了这个私有 API 了）
                                                                                                                                          

### 方案二：Ajax Hook 全部 API
这个方案对应的是这里的 `KKJSBridge/AjaxHook`。

原理介绍：此种方案，是使用 hook 的 XMLHttpRequest 对象来代理真实的 XMLHttpRequest 去发送请求，相当于是需要 hook ajax 中的所有方法，在 hook 的 open 方法里，调用 JSBridge 让 Native 去创建一个 NSMutableRequest 对象，然后在 hook 的 send 方法，把要发送的 body 通过 JSBridge 发送到 Native 侧，并把 body 设置给刚才创建的 NSMutableRequest 对象，并在 Native 侧完成请求后，通过 JS 执行函数，把请求结果通知给 JS 侧，JS 侧找到 hook 的 XMLHttpRequest 对象，最后调用 onreadystatechange 函数，让 H5 知道有请求结果了。

优点：

- 没有使用私有 API。


缺点：

- 需要 hook XMLHttpRequest 的所有方法。
- 请求结果是通过 JSBrdige 来进行传输的，性能上肯定没有原生的性能好。
- 不能支持 ajax 获取二进制的数据。要想支持的话，还需要额外的序列化工作。


## 更新历史
### 2020.11.24 (1.3.5)
- 模块化管理 TS，方便代码阅读和维护
- 移除 await 关键字，优化表单转 base64 的 js 代码

### 2020.11.21 (1.3.4)
- 支持 JSBridge 同步调用
- 支持 ajax 同步请求
- 支持通过 document.cookie 同步从 NSHTTPCookieStorage 读取最新的 Cookie

### 2020.10.21 (1.2.1)
- 正式版本，分别提供了 ajax hook 和 ajax urlprotocol hook 两种方案，可以根据具体需求自由选择。

### 2020.7.14 (1.1.5-beta9)
- 可以根据需求选择是 ajax hook 还是 ajax urlprotocol hook

### 2020.6.23 (1.1.5-beta2)

- 使用新的 hook 方式，提升 hook 兼容性 
- 支持 iframe 和 form 标签

### 2020.6.18 (1.1.0)
- 支持 fetch hook

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


## 特别鸣谢
非常感谢下面同学提的问题和建议

[![](https://github.com/wjiuxing.png?size=50)](https://github.com/wjiuxing)
[![](https://github.com/ZhangKejun.png?size=50)](https://github.com/ZhangKejun)


## 参考

- [Ajax-hook](https://github.com/wendux/Ajax-hook)

- [Fetch](https://github.com/github/fetch)

- [HybridPageKit](https://github.com/dequan1331/HybridPageKit)

- [kerkee_ios](https://github.com/kercer/kerkee_ios)


