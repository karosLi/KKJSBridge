//
//  KKJSBridgeURLRequestSerialization.h
//  KKJSBridge
//
//  Created by karos li on 2019/9/24.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KKJSBridgeStreamingMultipartFormData.h"

NS_ASSUME_NONNULL_BEGIN

@interface KKJSBridgeURLRequestSerialization : NSObject

- (void)multipartFormRequestWithRequest:(NSMutableURLRequest *)mutableRequest
                         parameters:(NSDictionary *)parameters
          constructingBodyWithBlock:(void (^)(id <KKJSBridgeMultipartFormData> formData))block
                              error:(NSError *__autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
