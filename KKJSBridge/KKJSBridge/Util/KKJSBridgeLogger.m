//
//  KKJSBridgeLogger.m
//  KKJSBridge
//
//  Created by karos li on 2019/7/24.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "KKJSBridgeLogger.h"
#import "KKJSBridgeJSExecutor.h"

@implementation KKJSBridgeLogger

+ (void)log:(NSString * _Nullable)prefix module:(NSString * _Nullable)module method:(NSString * _Nullable)method data:(id _Nullable)data {
#ifdef DEBUG
    NSString *str;
    if (![data isKindOfClass:[NSString class]]) {
        str = [KKJSBridgeJSExecutor serializeWithJson:data pretty:YES];
    } else {
        str = data;
    }
    
    if ([str length] > 500) {
        NSLog(@"KKJSBridge %@ %@.%@: %@ [...]", prefix, module, method, [str substringToIndex:500]);
    } else {
        NSLog(@"KKJSBridge %@ %@.%@: %@", prefix, module, method, str);
    }
#endif
}

@end
