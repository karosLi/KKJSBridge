//
//  ModuleA.m
//  KKJSBridgeDemo
//
//  Created by karos li on 2019/8/29.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "ModuleA.h"
#import <KKJSBridge/KKJSBridge.h>

@interface ModuleA()<KKJSBridgeModule>

@end

@implementation ModuleA

+ (nonnull NSString *)moduleName {
    return @"a";
}

//- (NSOperationQueue *)methodInvokeQueue {
//    static NSOperationQueue *queue;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        queue = [NSOperationQueue new];
//    });
//
//    return queue;
//}

- (void)callToAddOneForA:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    NSInteger a = [params[@"a"] integerValue];
    a++;
    responseCallback ? responseCallback(@{@"a": @(a)}) : nil;
}

@end
