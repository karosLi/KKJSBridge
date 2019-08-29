//
//  KKJSBridgeLogger.h
//  KKJSBridge
//
//  Created by karos li on 2019/7/24.
//  Copyright © 2019 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKJSBridgeLogger : NSObject

+ (void)log:(NSString * _Nullable)prefix module:(NSString * _Nullable)module method:(NSString * _Nullable)method data:(id _Nullable)data;

@end

NS_ASSUME_NONNULL_END
