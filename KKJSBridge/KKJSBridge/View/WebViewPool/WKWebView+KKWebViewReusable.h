//
//  WKWebView+KKWebViewReusable.h
//  KKJSBridge
//
//  Created by karos li on 2019/8/16.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol KKWebViewReusableProtocol <NSObject>
@optional

- (void)componentViewWillLeavePool;   //即将离开回收池
- (void)componentViewWillEnterPool;   //即将进入回收池

@end

@interface WKWebView (KKWebViewReusable)<KKWebViewReusableProtocol>

@property (nonatomic, weak, readwrite) NSObject *holderObject;
@property (nonatomic, assign, readwrite) NSInteger reusedTimes;
@property (nonatomic, assign, readwrite) BOOL invalid;

- (void)componentViewWillLeavePool __attribute__((objc_requires_super));   //即将离开回收池
- (void)componentViewWillEnterPool __attribute__((objc_requires_super));   //即将进入回收池

#pragma mark - clear backForwardList

- (void)_clearBackForwardList;

@end

NS_ASSUME_NONNULL_END
