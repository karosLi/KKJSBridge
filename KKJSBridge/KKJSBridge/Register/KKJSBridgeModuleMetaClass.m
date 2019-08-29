//
//  KKJSBridgeClass.m
//  KKJSBridge
//
//  Created by karos li on 2019/7/22.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "KKJSBridgeModuleMetaClass.h"

@interface KKJSBridgeModuleMetaClass()

@property (nonatomic, copy, readwrite) NSString *moduleName;
@property (nonatomic, strong, readwrite) Class moduleClass;
@property (nonatomic, assign, readwrite) BOOL isSingleton;
@property (nonatomic, strong, readwrite) id context;

@end

@implementation KKJSBridgeModuleMetaClass

- (instancetype)initWithModuleName:(NSString *)moduleName
                       moduleClass:(Class)moduleClass
                       isSingleton:(BOOL)isSingleton {
    return [self initWithModuleName:moduleName moduleClass:moduleClass isSingleton:isSingleton context:nil];
}

- (instancetype)initWithModuleName:(NSString *)moduleName
                       moduleClass:(Class)moduleClass
                       isSingleton:(BOOL)isSingleton context:(id _Nullable)context {
    if (self = [super init]) {
        _moduleName = [moduleName copy];
        _moduleClass = moduleClass;
        _isSingleton = isSingleton;
        _context = context;
    }
    
    return self;
}

@end
