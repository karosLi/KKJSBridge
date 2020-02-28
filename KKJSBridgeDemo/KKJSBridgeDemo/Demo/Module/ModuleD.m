//
//  ModuleD.m
//  KKJSBridgeDemo
//
//  Created by wjx on 2020/2/27.
//  Copyright © 2020 karosli. All rights reserved.
//

#import "ModuleD.h"
#import <KKJSBridge/KKJSBridge.h>

@interface ModuleD() <KKJSBridgeModule>

@end

@implementation ModuleD

+ (nonnull NSString *)moduleName
{
    return @"d";
}

+ (nonnull NSDictionary<NSString *, NSString *> *)methodInvokeMapper
{
    return @{@"fuck": @"d.raped"};
}

/// 将  {0: 'someTitle', 1: 'someUrl} 转成 {title: 'someTitle', url: 'someUrl'}，这里提供一种思路给强迫癌晚期患者：
/// 写一个方法 第一个标签为名字的 getter方法，返回 索引到key的映射。
+ (NSDictionary *)parameters:(NSDictionary *)parameters mappedForMethod:(NSString *)method
{
    if (nil == parameters
        || 0 == parameters.count) {
        return parameters;
    }
    
    SEL getter = NSSelectorFromString(method);
    if (![self respondsToSelector:getter]) {
        return parameters;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSArray *map = [self performSelector:getter];
#pragma clang diagnostic pop
    
    [map enumerateObjectsUsingBlock:^(NSArray * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *fuckKey = [NSString stringWithFormat:@"%lu", (unsigned long)idx];
        if ([entry isKindOfClass:[NSArray class]]) {
            if (0 == entry.count) {
                return;
            }
            
            NSString *key = entry.firstObject;
            id value = parameters[fuckKey];
            if (2 == entry.count
                && [entry.lastObject boolValue]) {
                NSError *error = nil;
                id tmp = [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
                if (nil != tmp && nil != error) {
                    value = tmp;
                }
            }
            
            params[key] = value;
        } else {
            params[(NSString *)(entry)] = parameters[fuckKey];
        }
    }];
    
    return params;
}

/// 以索引为 key 传来的 JOSN，这感觉就像被强奸了一样。
/// 取 raped:params:responseCallback: 方法的第一标签做 getter 方法的名字，返回索引到 key 的映射，
/// 如果值是 JSON 字符串需要被转换的，可以放数组，@[@"key", @YES]，第一个是 key，第二个表明是否需要 JSON 序列化操作。
+ (NSArray *)raped
{
    return @[
        @"title",
        @"content",
        @"url",
        @[@"userInfo", @YES],
        @[@"array", @YES]
    ];
}

- (void)raped:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback
{
    responseCallback(params);
}

@end
