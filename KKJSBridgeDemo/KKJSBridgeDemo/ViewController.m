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
     
     七牛token生成步骤：
     1、进入 KKJSBridge/KKJSBridge/TS
     2、npm install
     3、npm run qtoken
     */
    
    NSString *url = @"http://192.168.1.100:50000/index";
    {
        // 测试第三方网站 ajax 请求
//        url = @"https://m.taobao.com";
    }
    
//    url = @"https://www.wenjuan.com/s/JBVRje4/";
    
    WebViewController *web = [[WebViewController alloc] initWithUrl:url];
    [self.navigationController pushViewController:web animated:YES];
}

@end
