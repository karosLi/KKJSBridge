//
//  KKJSBridgeXMLHttpRequest.h
//  KKJSBridge
//
//  Created by karos li on 2019/7/23.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN
@class KKJSBridgeFormDataFile;
@class KKJSBridgeXMLHttpRequest;

@protocol KKJSBridgeModuleXMLHttpRequestDelegate <NSObject>

- (void)notifyDispatcherFetchComplete:(KKJSBridgeXMLHttpRequest *)xmlHttpRequest;
- (void)notifyDispatcherFetchFailed:(KKJSBridgeXMLHttpRequest *)xmlHttpRequest;

@end

@class KKJSBridgeEngine;

/**
 由 ajax 模块分发者创建的实际请求对象
 */
@interface KKJSBridgeXMLHttpRequest : NSObject

@property (nonatomic, weak, readonly) WKWebView *webView;
@property (nonatomic, strong, readonly) NSNumber *objectId;
@property (nonatomic, weak) id<KKJSBridgeModuleXMLHttpRequestDelegate> delegate;

- (instancetype)initWithObjectId:(NSNumber *)objectId engine:(KKJSBridgeEngine *)engine;
- (void)open:(NSString *)method url:(NSString *)url userAgent:(NSString *)userAgent referer:(NSString *)referer;
- (void)send;
- (void)send:(id)data;
- (void)sendFormData:(NSDictionary *)params withFileDatas:(NSArray<KKJSBridgeFormDataFile *> *)fileDatas;
- (void)setRequestHeader:(NSString *)headerName headerValue:(NSString *)headerValue;
- (void)overrideMimeType:(NSString *)mimeType;
- (BOOL)isOpened;
- (void)abort;

+ (void)evaluateJSToDeleteAjaxCache:(NSNumber *)objectId inWebView:(WKWebView *)webView;
+ (void)evaluateJSToSetAjaxProperties:(NSDictionary *)json inWebView:(WKWebView *)webView;

@end

NS_ASSUME_NONNULL_END
