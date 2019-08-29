//
//  KKJSBridgeWeakProxy.h
//  KKJSBridge
//
//  Created by karos li on 2019/7/25.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A proxy used to hold a weak object.
@interface KKJSBridgeWeakProxy : NSProxy

@property (nonatomic, weak, readonly) id target;

- (instancetype)initWithTarget:(id)target;
+ (instancetype)proxyWithTarget:(id)target;

@end

NS_ASSUME_NONNULL_END
