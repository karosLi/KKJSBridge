//
//  ModuleB.m
//  KKJSBridgeDemo
//
//  Created by karos li on 2019/8/29.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "ModuleB.h"
#import <KKJSBridge/KKJSBridge.h>
#import "ModuleContext.h"

@interface ModuleB()

@property (nonatomic, weak) ModuleContext *context;

@end

@implementation ModuleB

+ (nonnull NSString *)moduleName {
    return @"b";
}

//+ (NSOperationQueue *)methodInvokeQueue {
//    static NSOperationQueue *queue;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        queue = [NSOperationQueue new];
//    });
//
//    return queue;
//}

- (instancetype)initWithEngine:(KKJSBridgeEngine *)engine context:(id)context {
    if (self = [super init]) {
        _context = context;
        NSLog(@"ModuleB 初始化并带上 %@", self.context.name);
    }
    
    return self;
}

- (void)callToGetVCTitle:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    responseCallback ? responseCallback(@{@"title": self.context.vc.navigationItem.title ? self.context.vc.navigationItem.title : @""}) : nil;
}

@end
