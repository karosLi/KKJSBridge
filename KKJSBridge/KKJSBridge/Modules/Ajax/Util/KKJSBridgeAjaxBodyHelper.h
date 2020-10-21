//
//  KKJSBridgeAjaxBodyHelper.h
//  KKJSBridge
//
//  Created by karos li on 2020/7/9.
//  Copyright © 2020 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKJSBridgeAjaxBodyHelper : NSObject

+ (void)setBodyRequest:(NSDictionary *)bodyRequest toRequest:(NSMutableURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
