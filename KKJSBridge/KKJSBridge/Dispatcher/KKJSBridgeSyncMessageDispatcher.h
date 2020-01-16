//
//  KKJSBridgeSyncMessageDispatcher.h
//  AFNetworking
//
//  Created by wjx on 2020/8/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class KKJSBridgeEngine;
@class KKJSBridgeMessage;

@interface KKJSBridgeSyncMessageDispatcher : NSObject

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

@end

NS_ASSUME_NONNULL_END
