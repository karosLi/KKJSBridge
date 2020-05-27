//
//  KKJSBridgeMacro.h
//  KKJSBridge
//
//  Created by karos li on 2020/5/27.
//  Copyright © 2020 karosli. All rights reserved.
//
#import <Foundation/Foundation.h>

#ifndef KKJSBridgeMacro_h
#define KKJSBridgeMacro_h

#ifndef KKJS_LOCK
#define KKJS_LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#endif

#ifndef KKJS_UNLOCK
#define KKJS_UNLOCK(lock) dispatch_semaphore_signal(lock);
#endif

#endif /* KKJSBridgeMacro_h */
