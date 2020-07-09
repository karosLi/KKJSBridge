//
//  NSURLProtocol+KKJSBridgeWKWebView.h
//  KKJSBridge
//
//  Created by karos li on 2020/6/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLProtocol (KKJSBridgeWKWebView)

+ (void)KKJSBridgeRegisterScheme:(NSString *)scheme;
+ (void)KKJSBridgeUnregisterScheme:(NSString *)scheme;

@end

NS_ASSUME_NONNULL_END
