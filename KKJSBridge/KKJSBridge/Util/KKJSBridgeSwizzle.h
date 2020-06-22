//
//  KKJSBridgeSwizzle.h
//  KKJSBridge
//
//  Created by karos li on 2020/6/22.
//  Copyright © 2020 karosli. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT void KKJSBridgeSwizzleMethod(Class originalCls, SEL originalSelector, Class swizzledCls, SEL swizzledSelector);
