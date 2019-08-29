//
//  ModuleDefault.m
//  KKJSBridgeDemo
//
//  Created by karos li on 2019/8/29.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "ModuleDefault.h"
#import <KKJSBridge/KKJSBridge.h>

@implementation ModuleDefault

+ (nonnull NSString *)moduleName {
    return @"default";
}

- (void)callToTriggerEvent:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    [engine dispatchEvent:@"triggerEvent" data:@{@"eventData": @"dddd"}];
}

@end
