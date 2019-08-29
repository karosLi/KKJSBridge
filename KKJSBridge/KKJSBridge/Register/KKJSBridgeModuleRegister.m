//
//  KKJSBridgeRegister.m
//  KKJSBridge
//
//  Created by karos li on 2019/7/22.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "KKJSBridgeModuleRegister.h"

@interface KKJSBridgeModuleRegister()

@property (nonatomic, copy) NSMutableDictionary *moduleMetaClassMap;

@end

@implementation KKJSBridgeModuleRegister

- (instancetype)init {
    if (self = [super init]) {
        _moduleMetaClassMap = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (KKJSBridgeModuleMetaClass *)registerModuleClass:(Class<KKJSBridgeModule>)moduleClass {
    return [self registerModuleClass:moduleClass withContext:nil];
}

- (KKJSBridgeModuleMetaClass *)registerModuleClass:(Class<KKJSBridgeModule>)moduleClass withContext:(id _Nullable)context {
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
    return moduleMetaClass;
}

- (KKJSBridgeModuleMetaClass *)getModuleMetaClassByModuleName:(NSString *)moduleName {
    if (!moduleName) {
        return nil;
    }
    return self.moduleMetaClassMap[moduleName];
}

@end
