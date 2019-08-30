//
//  ModuleC.m
//  KKJSBridgeDemo
//
//  Created by karos li on 2019/8/30.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "ModuleC.h"
#import <KKJSBridge/KKJSBridge.h>

@interface ModuleC()<KKJSBridgeModule>

@end

@implementation ModuleC

+ (nonnull NSString *)moduleName {
    return @"c";
}

- (void)method:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    responseCallback ? responseCallback(@{@"desc": @"我是c模块"}) : nil;
}

@end
