//
//  KKJSBridgeStreamingMultipartFormData.h
//  KKJSBridge
//
//  Created by karos li on 2019/9/24.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KKJSBridgeMultipartFormData.h"

NS_ASSUME_NONNULL_BEGIN

@interface KKJSBridgeStreamingMultipartFormData : NSObject<KKJSBridgeMultipartFormData>

- (instancetype)initWithURLRequest:(NSMutableURLRequest *)urlRequest
                    stringEncoding:(NSStringEncoding)encoding;

- (NSMutableURLRequest *)requestByFinalizingMultipartFormData;

@end

NS_ASSUME_NONNULL_END
