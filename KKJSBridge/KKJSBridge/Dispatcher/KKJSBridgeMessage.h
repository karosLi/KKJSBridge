//
//  KKJSBridgeMessage.h
//  KKJSBridge
//
//  Created by karos li on 2019/7/22.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, KKJSBridgeMessageType) {
    KKJSBridgeMessageTypeCallback,
    KKJSBridgeMessageTypeEvent,
    KKJSBridgeMessageTypeSyncCall,
};

/**
 统一 JSBridge 消息，封装来自 H5 的消息体和需要发送给 H5 回调的消息体
*/
@interface KKJSBridgeMessage : NSObject

@property (nonatomic, assign) KKJSBridgeMessageType messageType;
@property (nonatomic, copy, nullable) NSDictionary *data;

#pragma mark - callback 相关
@property (nonatomic, copy, nullable) NSString *module;
@property (nonatomic, copy, nullable) NSString *method;
@property (nonatomic, copy, nullable) NSString *callbackId;

/// 同步 JS call 的回调
@property (nonatomic, copy, nullable) void (^syncCallback)(NSDictionary *responseData);

#pragma mark - event 相关
@property (nonatomic, copy, nullable) NSString *eventName;

@end

NS_ASSUME_NONNULL_END
