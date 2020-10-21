//
//  KKJSBridgeXMLBodyCacheRequest.m
//  KKJSBridge
//
//  Created by karos li on 2020/6/20.
//  Copyright © 2020 karosli. All rights reserved.
//

#import "KKJSBridgeXMLBodyCacheRequest.h"
#import "KKJSBridgeModuleRegister.h"
#import "KKJSBridgeEngine.h"
#import "KKJSBridgeAjaxURLProtocol.h"
#import "KKJSBridgeSafeDictionary.h"

static KKJSBridgeSafeDictionary *bodyCache;

@interface KKJSBridgeXMLBodyCacheRequest()<KKJSBridgeModule>
@property (nonatomic, copy) NSOperationQueue *queue;
@end

@implementation KKJSBridgeXMLBodyCacheRequest

+ (void)initialize {
    if (self == [KKJSBridgeXMLBodyCacheRequest self]) {
        [NSURLProtocol registerClass:KKJSBridgeAjaxURLProtocol.class];
        bodyCache = [KKJSBridgeSafeDictionary new];
    }
}

+ (nonnull NSString *)moduleName {
    return @"ajax";
}

+ (BOOL)isSingleton {
    return true;
}

- (instancetype)initWithEngine:(KKJSBridgeEngine *)engine context:(id)context {
    if (self = [super init]) {
        _queue = [NSOperationQueue new];
        _queue.maxConcurrentOperationCount = 5;
    }
    
    return self;
}

- (NSOperationQueue *)methodInvokeQueue {
    return self.queue;
}

/**
  {
     //请求唯一id
     requestId,
     //当前 href url
     requestHref,
     //请求 Url
     requestUrl,
     //body 类型
     bodyType
     //表单编码类型
     formEnctype
     //body 具体值
     value
 }
 */
- (void)cacheAJAXBody:(KKJSBridgeEngine *)engine params:(NSDictionary *)params responseCallback:(void (^)(NSDictionary *responseData))responseCallback {
    NSString *requestId = params[@"requestId"];
    bodyCache[requestId] = params;
    
    if (responseCallback && requestId) {
        responseCallback(@{@"requestId": requestId,
                           @"requestUrl": params[@"requestUrl"] ? params[@"requestUrl"] : @""
                         });
    }
}

+ (NSDictionary *)getRequestBody:(NSString *)requestId {
    if (!requestId) {
        return nil;
    }
    
    return bodyCache[requestId];
}

+ (void)deleteRequestBody:(NSString *)requestId {
    if (!requestId) {
        return;
    }
    
    return [bodyCache removeObjectForKey:requestId];
}

@end
