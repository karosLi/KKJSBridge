//
//  KKJSBridgeClass.h
//  KKJSBridge
//
//  Created by karos li on 2019/7/22.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 用于为注册的模块创建一对一的元类，元类用于描述模块的属性和行为
 */
@interface KKJSBridgeModuleMetaClass : NSObject

- (instancetype)initWithModuleName:(NSString *)moduleName
                       moduleClass:(Class)moduleClass
                       isSingleton:(BOOL)isSingleton;

- (instancetype)initWithModuleName:(NSString *)moduleName
                       moduleClass:(Class)moduleClass
                       isSingleton:(BOOL)isSingleton
                           context:(id _Nullable)context;

@property (nonatomic, copy, readonly) NSString *moduleName;
@property (nonatomic, strong, readonly) Class moduleClass;
@property (nonatomic, assign, readonly) BOOL isSingleton;
@property (nonatomic, strong, readonly, nullable) id context;

@end

NS_ASSUME_NONNULL_END
