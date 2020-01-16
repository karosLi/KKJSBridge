//
//  KKJSBridgeSyncMessageDispatcher.m
//  AFNetworking
//
//  Created by wjx on 2020/8/11.
//

#import "KKJSBridgeSyncMessageDispatcher.h"
#import <objc/message.h>
#import "KKJSBridgeJSExecutor.h"
#import "KKJSBridgeEngine.h"
#import "KKJSBridgeMessage.h"
#import "KKJSBridgeModuleRegister.h"
#import "KKJSBridgeLogger.h"

typedef void (^KKJSBridgeMessageCallback)(NSDictionary *responseData);

@interface KKJSBridgeSyncMessageDispatcher()

@property (nonatomic, weak) KKJSBridgeEngine *engine;

@end

@implementation KKJSBridgeSyncMessageDispatcher

- (instancetype)initWithEngine:(KKJSBridgeEngine *)engine {
    if (self = [super init]) {
        _engine = engine;
    }
    
    return self;
}

- (KKJSBridgeMessage *)convertMessageFromMessageJson:(NSDictionary *)json {
    KKJSBridgeMessage *message = [KKJSBridgeMessage new];
    message.module = json[@"module"];
    message.method = json[@"method"];
    message.data = json[@"data"];
    message.callbackId = json[@"callbackId"];
    
    return message;
}

- (void)dispatchCallbackMessage:(KKJSBridgeMessage *)message {
    // 收到消息表示已经准备好了
    if (!self.engine.bridgeReady) {
        self.engine.bridgeReady = YES;
        if (self.engine.bridgeReadyCallback) {
            self.engine.bridgeReadyCallback(self.engine);
        }
    }
    
    NSString *moduleName = message.module;
    NSString *methodName = message.method;
    NSDictionary *params = message.data;
    if (!moduleName || !methodName) {
#ifdef DEBUG
        NSLog(@"KKJSBridge Error: module or method is not found");
#endif
        return;
    }
    
    KKJSBridgeModuleMetaClass *metaClass = [self.engine.moduleRegister getModuleMetaClassByModuleName:moduleName];
    if (!metaClass) {
#ifdef DEBUG
        NSLog(@"KKJSBridge Error: module %@ is not registered", moduleName);
#endif
        return;
    }
    
    Class nativeClass = metaClass.moduleClass;
    Class<KKJSBridgeModule> moduleClass = nativeClass;
    
    // 参数映射方法，默认是原方法的第一标签
    NSString *parametersMappingMethod = methodName;
    
    // 方法调用映射，只做一层映射，不会递归处理
    if ([moduleClass respondsToSelector:@selector(methodInvokeMapper)]) {
        NSDictionary *methodMapper = [moduleClass methodInvokeMapper];
        NSString *value = methodMapper[methodName];
        if ([value rangeOfString:@"."].location != NSNotFound) {
            NSArray<NSString *> *components = [value componentsSeparatedByString:@"."];
            if (components.count == 2) {
                moduleName = components[0];
                methodName = components[1];
                
                metaClass = [self.engine.moduleRegister getModuleMetaClassByModuleName:moduleName];
                if (!metaClass) {
#ifdef DEBUG
                    NSLog(@"KKJSBridge Error: module %@ is not registered", moduleName);
#endif
                    return;
                }
                
                nativeClass = metaClass.moduleClass;
                moduleClass = nativeClass;
                
                // 参数映射方法，改成要转发的方法的第一标签
                parametersMappingMethod = methodName;
            }
        }
    }
    
    if ([moduleClass respondsToSelector:@selector(parameters:mappedForMethod:)]) {
        NSDictionary *tmp = ((NSDictionary *(*)(id, SEL, NSDictionary *, NSString *))objc_msgSend)(moduleClass, @selector(parameters:mappedForMethod:), params, parametersMappingMethod);
        if (nil != tmp) {
            params = tmp;
        }
    }
    
    /**
     模块初始化
     */
    id instance = [self.engine.moduleRegister generateInstanceFromMetaClass:metaClass];
    
    /**
     模块方法调用与回调处理
     */
    if (instance) {
        NSString *apiMethodName = [NSString stringWithFormat:@"%@:params:responseCallback:", methodName];
        SEL apiMethodNameSEL = NSSelectorFromString(apiMethodName);
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([instance respondsToSelector:apiMethodNameSEL]) { // 在调用实际 API
            [KKJSBridgeLogger log:@"Receive" module:moduleName method:methodName data:params];
#ifdef DEBUG
            CFTimeInterval start = CFAbsoluteTimeGetCurrent();
#endif
            ((void (*)(id, SEL, KKJSBridgeEngine *, NSDictionary *, KKJSBridgeMessageCallback))objc_msgSend)(instance, apiMethodNameSEL, self.engine, params, message.syncCallback);
#ifdef DEBUG
            CFTimeInterval end = CFAbsoluteTimeGetCurrent();
            CFTimeInterval duration = (end - start) * 1000.0;
            if (duration > 16) {
                NSLog(@"KKJSBridge Warnning: %@:%@ took '%f' ms.", moduleName, methodName, duration);
            }
#endif
        } else {
#ifdef DEBUG
            NSLog(@"KKJSBridge Error: method %@ is not defined in module %@", methodName, moduleName);
#endif
        }
#pragma clang diagnostic pop
    }
}

@end
