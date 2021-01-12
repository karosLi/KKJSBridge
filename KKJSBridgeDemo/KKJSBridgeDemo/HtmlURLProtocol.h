//
//  HtmlURLProtocol.h
//  KKJSBridgeDemo
//
//  Created by karos li on 2020/7/22.
//  Copyright © 2020 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HtmlURLProtocol : NSURLProtocol
+ (void)HtmlURLProtocolRegisterScheme:(NSString *)scheme;
+ (void)HtmlURLProtocolUnregisterScheme:(NSString *)scheme;
@end

NS_ASSUME_NONNULL_END
