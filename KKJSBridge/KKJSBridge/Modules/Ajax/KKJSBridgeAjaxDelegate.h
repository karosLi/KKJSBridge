//
//  KKJSBridgeAjaxDelegate.h
//  KKJSBridge
//
//  Created by karos li on 2019/7/26.
//  Copyright © 2019 karosli. All rights reserved.
//

#ifndef KKJSBridgeAjaxDelegate_h
#define KKJSBridgeAjaxDelegate_h
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class KKJSBridgeXMLHttpRequest;

/**
 需要回传给 ajax 的回调实现
 */
@protocol KKJSBridgeAjaxDelegate <NSObject>

@required
- (void)JSBridgeAjax:(id<KKJSBridgeAjaxDelegate>)ajax didReceiveResponse:(NSURLResponse *)response;
- (void)JSBridgeAjax:(id<KKJSBridgeAjaxDelegate>)ajax didReceiveData:(NSData *)data;
- (void)JSBridgeAjax:(id<KKJSBridgeAjaxDelegate>)ajax didCompleteWithError:(NSError * _Nullable)error;

@end

/**
 Ajax 请求代理管理者，用于统一代理 JSBridge Ajax 内部请求，交由外部网络库来处理请求，并把处理结果回传给内部
 */
@protocol KKJSBridgeAjaxDelegateManager <NSObject>

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request callbackDelegate:(NSObject<KKJSBridgeAjaxDelegate> *)callbackDelegate;

@end

NS_ASSUME_NONNULL_END
#endif /* KKJSBridgeAjaxDelegate_h */
