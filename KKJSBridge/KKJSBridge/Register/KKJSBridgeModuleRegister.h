//
//  KKJSBridgeRegister.h
//  KKJSBridge
//
//  Created by karos li on 2019/7/22.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KKJSBridgeModuleMetaClass.h"

NS_ASSUME_NONNULL_BEGIN
@class KKJSBridgeEngine;

@protocol KKJSBridgeModule <NSObject>

+ (NSString *)moduleName; // 配置模块名

@optional
+ (BOOL)isSingleton; // 是否是单例模块

/**
 方法调用映射。只做一层映射，不会递归处理。即只会把 a 模块的方法映射到 b 模块里，不会又继续映射到 c 模块里。
 适用场景：
 1、前期只定义了一个模块，后期想要分模块
 2、前期模块规划混乱，后期想要治理模块
 
 例子：本模块的 method 方法，会被映射到 b 模块的 method 方法
 + (nonnull NSDictionary<NSString *, NSString *> *)methodInvokeMapper {
    return @{@"method": @"b.method"};
 }

 @return NSDictionary
 */
+ (NSDictionary<NSString *, NSString *> *)methodInvokeMapper;

- (instancetype)initWithEngine:(KKJSBridgeEngine *)engine context:(id)context; // 模块初始化，适合用于需要借助外部环境才能调用 API 的场景
- (NSOperationQueue * _Nullable)methodInvokeQueue; // 方法调用 queue。默认是 mainQueue，当考虑性能原因时，外部可以指定方法调用的自定义 queue。

@end

/**
 模块注册者，每个 JSBridge 有自己单独的注册者，保持独立
 */
@interface KKJSBridgeModuleRegister : NSObject

- (instancetype)initWithEngine:(KKJSBridgeEngine *)engine;

/**
 注册模块

 @param moduleClass 模块类
 @return 模块元类
 */
- (KKJSBridgeModuleMetaClass *)registerModuleClass:(Class<KKJSBridgeModule>)moduleClass;

/**
 注册模块并带上上下文

 @param moduleClass 模块类
 @param context 上下文
 @return 模块元类
 */
- (KKJSBridgeModuleMetaClass *)registerModuleClass:(Class<KKJSBridgeModule>)moduleClass withContext:(id _Nullable)context;

/**
 注册模块并带上上下文，并决定是否提前初始化一次
 
 @param moduleClass 模块类
 @param context 上下文
 @param initialize 是否需要初始化
 @return 模块元类
 */
- (KKJSBridgeModuleMetaClass *)registerModuleClass:(Class<KKJSBridgeModule>)moduleClass withContext:(id _Nullable)context initialize:(BOOL)initialize;


/**
 根据模块名称获取模块元类

 @param moduleName 模块名称
 @return 模块元类
 */
- (KKJSBridgeModuleMetaClass *)getModuleMetaClassByModuleName:(NSString *)moduleName;

/**
 生成模块实例
 
 @param metaClass 模块类
 @return 模块实例
 */
- (id)generateInstanceFromMetaClass:(KKJSBridgeModuleMetaClass *)metaClass;

@end

NS_ASSUME_NONNULL_END
