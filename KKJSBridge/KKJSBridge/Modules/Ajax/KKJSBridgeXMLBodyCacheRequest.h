//
//  KKJSBridgeXMLBodyCacheRequest.h
//  KKJSBridge
//
//  Created by karos li on 2020/6/20.
//  Copyright © 2020 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 用于缓存 ajax body 
 */
@interface KKJSBridgeXMLBodyCacheRequest : NSObject

+ (NSDictionary *)getRequestBody:(NSString *)requestId;
+ (void)deleteRequestBody:(NSString *)requestId;

@end

NS_ASSUME_NONNULL_END
