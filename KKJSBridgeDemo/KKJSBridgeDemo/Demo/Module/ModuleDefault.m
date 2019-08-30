//
//  ModuleDefault.m
//  KKJSBridgeDemo
//
//  Created by karos li on 2019/8/29.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "ModuleDefault.h"
#import <KKJSBridge/KKJSBridge.h>

@interface ModuleDefault()<KKJSBridgeModule>

@end

@implementation ModuleDefault

+ (nonnull NSString *)moduleName {
    return @"default";
}

+ (nonnull NSDictionary<NSString *, NSString *> *)methodInvokeMapper {
    // 消息转发，可以把 本模块的消息转发到 c 模块里
    return @{@"method": @"c.method"};
}

- (void)callToTriggerEvent:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    [engine dispatchEvent:@"triggerEvent" data:@{@"eventData": @"dddd"}];
}

- (void)method:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    responseCallback ? responseCallback(@{@"desc": @"我是默认模块"}) : nil;
}

@end
