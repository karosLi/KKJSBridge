//
//  KKJSBridgeRegister.m
//  KKJSBridge
//
//  Created by karos li on 2019/7/22.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "KKJSBridgeModuleRegister.h"
#import <objc/message.h>
#import "KKJSBridgeSafeDictionary.h"

@interface KKJSBridgeModuleRegister()

@property (nonatomic, weak) KKJSBridgeEngine *engine;
@property (nonatomic, copy) KKJSBridgeSafeDictionary *moduleMetaClassMap;
@property (nonatomic, copy) KKJSBridgeSafeDictionary *singletonMetaClassMap;

@end

@implementation KKJSBridgeModuleRegister

- (instancetype)initWithEngine:(KKJSBridgeEngine *)engine {
    if (self = [super init]) {
        _engine = engine;
        _moduleMetaClassMap = [KKJSBridgeSafeDictionary dictionary];
        _singletonMetaClassMap = [KKJSBridgeSafeDictionary dictionary];
    }
    
    return self;
}

- (KKJSBridgeModuleMetaClass *)registerModuleClass:(Class<KKJSBridgeModule>)moduleClass {
    return [self registerModuleClass:moduleClass withContext:nil];
}

- (KKJSBridgeModuleMetaClass *)registerModuleClass:(Class<KKJSBridgeModule>)moduleClass withContext:(id _Nullable)context {
    return [self registerModuleClass:moduleClass withContext:context initialize:NO];
}

- (KKJSBridgeModuleMetaClass *)registerModuleClass:(Class<KKJSBridgeModule>)moduleClass withContext:(id _Nullable)context initialize:(BOOL)initialize {
    if (!moduleClass) {
        return nil;
    }
    
    NSString *moduleName;
    if ([moduleClass respondsToSelector:@selector(moduleName)]) {
        moduleName = [(id<KKJSBridgeModule>)moduleClass moduleName];
    }
    
    if (!moduleName) {
        return nil;
    }
    
    BOOL isSingleton = NO;
    if ([moduleClass respondsToSelector:@selector(isSingleton)]) {
        isSingleton = [(id<KKJSBridgeModule>)moduleClass isSingleton];
    }
    
    KKJSBridgeModuleMetaClass *moduleMetaClass = [[KKJSBridgeModuleMetaClass alloc] initWithModuleName:moduleName moduleClass:moduleClass isSingleton:isSingleton context:context];
    self.moduleMetaClassMap[moduleName] = moduleMetaClass;
    
    if (initialize) {
        [self generateInstanceFromMetaClass:moduleMetaClass];
    }
    
    return moduleMetaClass;
}

- (KKJSBridgeModuleMetaClass *)getModuleMetaClassByModuleName:(NSString *)moduleName {
    if (!moduleName) {
        return nil;
    }
    return self.moduleMetaClassMap[moduleName];
}

- (id)generateInstanceFromMetaClass:(KKJSBridgeModuleMetaClass *)metaClass {
    Class nativeClass = metaClass.moduleClass;
    NSString *moduleName = metaClass.moduleName;
    
    id context = metaClass.context;
    
    NSString *initContextMethodName = @"initWithEngine:context:";
    SEL initContextMethodSEL = NSSelectorFromString(initContextMethodName);
    
    /**
     模块初始化
     */
    id instance;
    if (metaClass.isSingleton) { // 单例模块需要先从缓存里取，如果不存在则需要创建，并保存到缓存里
        id cacheInstance = self.singletonMetaClassMap[moduleName];
        if (!cacheInstance) {
            id allocClass = [nativeClass alloc];
            if ([allocClass respondsToSelector:initContextMethodSEL]) { // 先处理上下文
                cacheInstance = ((id (*)(id, SEL, KKJSBridgeEngine *, id))objc_msgSend)(allocClass, initContextMethodSEL, self.engine, context);
            } else {
                cacheInstance = [[nativeClass alloc] init];
            }
            
            self.singletonMetaClassMap[moduleName] = cacheInstance;
        }
        
        instance = cacheInstance;
    } else {
        id allocClass = [nativeClass alloc];
        if ([allocClass respondsToSelector:initContextMethodSEL]) { // 先处理上下文
            instance = ((id (*)(id, SEL, KKJSBridgeEngine *, id))objc_msgSend)(allocClass, initContextMethodSEL, self.engine, context);
        } else {
            instance = [[nativeClass alloc] init];
        }
    }
    
    return instance;
}

@end
