//
//  ViewController.m
//  KKJSBridgeDemo
//
//  Created by karos li on 2019/8/29.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "ViewController.h"
#import "WebViewController.h"
#import "HtmlURLProtocol.h"
#import <KKJSBridge/KKJSBridge.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"加载" style:UIBarButtonItemStylePlain target:self action:@selector(load)];
    NSString *libraryPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask,YES).firstObject;
    NSLog(@"libraryPath = %@", libraryPath);
    
    // 注册 HtmlURLProtocol，使用离线包
#ifndef KKAjaxProtocolHook
    [HtmlURLProtocol HtmlURLProtocolRegisterScheme:@"http"];
    [HtmlURLProtocol HtmlURLProtocolRegisterScheme:@"https"];
#endif
    [NSURLProtocol registerClass:HtmlURLProtocol.class];
}

- (void)load {
    /**
     运行demo步骤：
     1、进入 KKJSBridgeDemo/KKJSBridgeDemo/Software/Server 目录
     2、基于上面目录打开终端，并运行 node server.js
     3、打开 KKJSBridgeDemo/KKJSBridgeDemo.xcworkspace 运行 demo
     
     七牛token生成步骤：
     1、进入 KKJSBridge/KKJSBridge/TS
     2、npm install
     3、npm run qtoken
     */
    
    NSString *url = @"http://127.0.0.1:50000/index";
    {
        // 测试第三方网站 ajax 请求
//        url = @"https://m.taobao.com";
//        url = @"https://www.wenjuan.com/s/JBVRje4/";
//        url = @"https://i.meituan.com/";
//        url = @"https://h5.ele.me/";
    }

    {
        // 测试 file 协议
//        NSMutableDictionary *properties = [NSMutableDictionary dictionary];
//        properties[NSHTTPCookieName] = @"kktoken";
//        properties[NSHTTPCookieValue] = @"ASDFSAOBFDSLFL";
//        properties[NSHTTPCookiePath] = @"/";
//        properties[NSHTTPCookieDomain] = @"127.0.0.1";
//        properties[NSHTTPCookieExpires] = @"Mon, 01 Aug 2050 06:44:35 GMT";
//        NSHTTPCookie *cookieObject = [NSHTTPCookie cookieWithProperties:properties];
//        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookieObject];
//        NSString *path = [[NSBundle mainBundle] pathForResource:@"ajaxHookTestLocalFile" ofType:@"html"];
//        url = [NSString stringWithFormat:@"file://%@", path];
    }
    url = @"https://h5.leoao.com/fit-m/#/pages/pt/index";
    url = @"https://h5.leoao.com/multiple/coach/cert.html#/certEdit";
    url = @"http://www.baidu.com";
    WebViewController *web = [[WebViewController alloc] initWithUrl:url];
    [self.navigationController pushViewController:web animated:YES];
}

- (void)testRegex {
    NSString *url1 = @"http://172.16.14.8:50000/testAjaxPost?KKJSBridge-RequestId=159287956902898111";
    BOOL flag = [self validateRequestId:url1];
    NSLog(@"-----------%d", flag);
    NSString *str = [self fetchMatchedTextFromUrl:url1 withRegex:@"^.*?[&|\\?]?KKJSBridge-RequestId=(\\d+).*?$"];
    NSLog(@"-----------%@", str);
    NSString *str1 = [self fetchMatchedTextFromUrl:url1 withRegex:@"^.*?([&|\\?]?KKJSBridge-RequestId=\\d+).*?$"];
    NSLog(@"-----------%@", str1);
}

- (BOOL)validateRequestId:(NSString *)url
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^.*?[&|\\?]?KKJSBridge-RequestId=(\\d+).*?$"];
    return [predicate evaluateWithObject:url];
}

- (NSString *)fetchMatchedTextFromUrl:(NSString *)url withRegex:(NSString *)regexString {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:NULL];
    NSArray *matches = [regex matchesInString:url options:0 range:NSMakeRange(0, url.length)];
    NSString *content;
    for (NSTextCheckingResult *match in matches) {
        for (int i = 0; i < [match numberOfRanges]; i++) {
            //以正则中的(),划分成不同的匹配部分
            content = [url substringWithRange:[match rangeAtIndex:i]];
            if (i == 1) {
                return content;
            }
        }
    }
    
    return content;
}

@end
