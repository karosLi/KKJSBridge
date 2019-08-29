//
//  KKJSBridgeConfig.m
//  KKJSBridge
//
//  Created by karos li on 2019/7/25.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "KKJSBridgeConfig.h"
#import "KKJSBridgeJSExecutor.h"
#import "KKJSBridgeEngine.h"

@interface KKJSBridgeConfig()<KKJSBridgeModule>

@end

@implementation KKJSBridgeConfig

+ (nonnull NSString *)moduleName {
    return @"bridgeConfig";
}

+ (BOOL)isSingleton {
    return true;
}

#pragma mark - 把外部设置提供给 JSBridge
- (void)fetchConfig:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    NSMutableDictionary *config = [NSMutableDictionary dictionary];
    config[@"isEnableAjaxHook"] = @(engine.config.isEnableAjaxHook);
    
    responseCallback ? responseCallback(config) : nil;
}

#pragma mark - 接受来自 JSBridge 的设置
- (void)receiveConfig:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    if (params[@"isEnableAjaxHook"]) {
        BOOL isAjaxHook = [params[@"isEnableAjaxHook"] boolValue];
        engine.config.enableAjaxHook = isAjaxHook;
    }
    
    responseCallback ? responseCallback(nil) : nil;
}

@end
