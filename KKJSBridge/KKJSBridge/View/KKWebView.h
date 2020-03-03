//
//  KKWebView.h
//  KKJSBridge
//
//  Created by karos li on 2019/7/29.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "WKWebView+KKWebViewExtension.h"

NS_ASSUME_NONNULL_BEGIN

@protocol KKWebViewDelegate <WKNavigationDelegate>

@end

/**
 WKWebView hybird 容器。并能够在容器内部自管理 cookie。
 
 讨论：内部解决了如下 cookie 同步的问题
 1、同步首次请求的 cookie，是设置请求头来保持 cookie 同步（把 NSHTTPCookieStorage 同步到 WKWebView cookie）。
 2、为异步 ajax 请求同步 cookie，是使用 ajax cookie js 注入去保持 cookie 同步（把 NSHTTPCookieStorage 同步到 WKWebView cookie）。
 3、对服务器端重定向(302)/浏览器重定向(a标签[包括 target="_blank"]) 进行同步 cookie 处理（把 NSHTTPCookieStorage 同步到 WKWebView cookie）。
 4、捕获链接跳转的服务器端响应头里的 Set-Cookie，来保持 cookie 同步，也兼容了 iOS 11 以下和以上（把 WKWebView cookie 同步到 NSHTTPCookieStorage）。
 5、处理手动修改 document.cookie 时无法触发同步的问题。当在 H5 侧执行 document.cookie='qq=55x; domain=172.16.12.72; path=/; expires=Mon, 01 Aug 2050 06:44:35 GMT; Secure' 时，cookie 的修改信息只会同步到 WKWebView cookie 里，此时就需要通过 hook document.cookie 来监听来自 H5 侧对 cookie 的修改，然后把修改后的 cookie 信息同步到 NSHTTPCookieStorage 里。而这部分的处理需要借助 KKJSBridgeEngine 的 cookie hook 来处理了。
 
 注意的问题：
 1、处理 ajax response Set-Cookie 同步问题，此时 Set-Cookie 并不会触发 document.cookie 设置 cookie。一般只有登录相关的 ajax 请求才会在 response 里返回 Set-Cookie。好在 Hybird WebView 都是以 native 的登录 cookie 为准，这种情况影响不大，主要是需要跟前端约定好。
 2、处理 cookie HTTPOnly 问题，因为一旦设置了 HTTPOnly，则意味着 通过 document.cookie 是获取不到该 cookie，而实际发送请求时，还是会发送出去的。
    2.1、如果 HTTPOnly 类 cookie 也是在 native 上的登录接口返回的，而通过 ajax cookie js 注入去同步 cookie 时，HTTPOnly cookie 也是可以发送让 ajax 携带并发送的。
    2.2、如果 HTTPOnly 类 cookie 是在 H5 侧通过 ajax reposne Set-Cookie HttpOnly 设置的，这种情况处理不了，因为从 document.cookie 本身是读取不到 HTTPOnly 类 cookie 的。所以还是建议针对这类 cookie 最好是通过 native 来管理。
 
 针对上面注意问题 1，可以结合 KKJSBridgeEngine 开启 ajax hook 来解决，因为开启后，所有的 ajax 都是走的 native 发送请求，request 自动从 NSHTTPCookieStorage 获取 cookie，并且 response Set-Cookie 也都会存在 NSHTTPCookieStorage 里。
 针对上面注意问题 2，也可以结合 KKJSBridgeEngine 开启 ajax hook 来解决，原因同上，natvie 发送的请求时不会依赖 document.cookie 的。
 

 帮助：
 1、这个链接里的 python 代码可以解析目录 Library/Cookies 下的 WKWebView cookie 和 NSHTTPCookieStorage 的二进制文件。
    https://gist.github.com/sh1n0b1/4bb8b737370bfe5f5ab8。
 2、WKWebView cookie 文件名：Cookie.binarycookies
     > Python BinaryCookieReader.py ./Cookies.binarycookies
     Cookie : test_token2=2; domain=172.16.12.72; path=/; expires=Mon, 01 Aug 2050;
     Cookie : test_token3=3; domain=172.16.12.72; path=/; expires=Mon, 01 Aug 2050; HttpOnly
 3、NSHTTPCookieStorage cookie 文件名：<appid>.binarycookies
     > Python BinaryCookieReader.py ./com.xxx.KKWebView.binarycookies
     Cookie : test_token2=2; domain=172.16.12.72; path=/; expires=Mon, 01 Aug 2050;
     Cookie : test_token3=3; domain=172.16.12.72; path=/; expires=Mon, 01 Aug 2050; HttpOnly
 4、从 binarycookies 文件的解析结果可以看到 Session Cookie(没有设置 expires) 是不会持久化的。
 
 */
@interface KKWebView : WKWebView

@end

NS_ASSUME_NONNULL_END
