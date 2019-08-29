//
//  KKJSBridgeMessageDispatcher.h
//  KKJSBridge
//
//  Created by karos li on 2019/7/22.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class KKJSBridgeEngine;
@class KKJSBridgeMessage;

/**
 统一消息分发者，分发所有来自 H5 的消息，并处理消息回调
 */
@interface KKJSBridgeMessageDispatcher : NSObject

- (instancetype)initWithEngine:(KKJSBridgeEngine *)engine;

/**
 转换 json 到 message 对象

 @param json message json
 @return message 对象
 */
- (KKJSBridgeMessage *)convertMessageFromMessageJson:(NSDictionary *)json;

/**
 分发回调消息消息

 @param message 消息
 */
- (void)dispatchCallbackMessage:(KKJSBridgeMessage *)message;


/**
 分发事件消息

 @param eventName 事件名称
 @param data 实际数据
 */
- (void)dispatchEventMessage:(NSString *)eventName data:(NSDictionary * _Nullable)data;

@end

NS_ASSUME_NONNULL_END
