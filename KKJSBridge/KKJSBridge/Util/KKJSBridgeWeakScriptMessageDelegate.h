//
//  KKJSBridgeWeakScriptMessageDelegate.h
//  KKJSBridge
//
//  Created by karos li on 2019/7/23.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKJSBridgeWeakScriptMessageDelegate : NSObject<WKScriptMessageHandler>

@property (nonatomic, weak, readonly) id<WKScriptMessageHandler> scriptDelegate;

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate;

@end

NS_ASSUME_NONNULL_END
