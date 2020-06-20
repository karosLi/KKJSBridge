//
//  KKJSBridgeSafeDictionary.h
//  KKJSBridge
//
//  Created by karos li on 2020/6/20.
//  Copyright © 2020 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 单线程写，多线程读
 */
@interface KKJSBridgeSafeDictionary : NSMutableDictionary

@end

NS_ASSUME_NONNULL_END
