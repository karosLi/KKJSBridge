//
//  ViewController.m
//  KKJSBridgeDemo
//
//  Created by karos li on 2019/8/29.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "ViewController.h"
#import "WebViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"加载" style:UIBarButtonItemStylePlain target:self action:@selector(load)];
    NSString *libraryPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask,YES).firstObject;
    NSLog(@"libraryPath = %@", libraryPath);
}

- (void)load {
    /**
     运行demo步骤：
     1、进入 KKJSBridgeDemo/KKJSBridgeDemo/Software/Server 目录
     2、基于上面目录打开终端，并运行 node server.js
     3、打开 KKJSBridgeDemo/KKJSBridgeDemo.xcworkspace 运行 demo
     */
    
    
    NSString *url = @"";
    {
        // 测试JSBridge
//        url = @"http://127.0.0.1:50000/moduleTest";
    }
    {
        // 测试 ajax 和 set-cookie
//        url = @"http://127.0.0.1:50000/index";
    }
    {
        // 测试服务器端重定向
        url = @"http://127.0.0.1:50000/index302";
    }
    {
        // 测试第三方网站 ajax 请求
//        url = @"https://m.taobao.com";
    }
    {
        // 测试表单
//        url = @"http://127.0.0.1:50000/formData";
    }
    
    WebViewController *web = [[WebViewController alloc] initWithUrl:url];
    [self.navigationController pushViewController:web animated:YES];
}

@end
