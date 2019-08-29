//
//  WKWebView+KKWebViewExtension.h
//  KKJSBridge
//
//  参考的是 HybridPageKit
//
//  Created by karos li on 2019/7/29.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM (NSInteger, KKWebViewConfigUAType) {
    KKWebViewConfigUATypeReplace,     //replace all UA string
    KKWebViewConfigUATypeAppend,      //append to original UA string
};

@interface WKWebView (KKWebViewExtension)

#pragma mark - UA
+ (void)configCustomUAWithType:(KKWebViewConfigUAType)type
                      UAString:(NSString *)customString;

#pragma mark - clear webview cache

+ (void)safeClearAllCacheIncludeiOS8:(BOOL)includeiOS8;

@end

NS_ASSUME_NONNULL_END
