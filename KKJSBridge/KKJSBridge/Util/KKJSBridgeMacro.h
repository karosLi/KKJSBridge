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

#ifndef KKJS_SAFE_DISPATCH_ASYNC_MAIN
#define KKJS_SAFE_DISPATCH_ASYNC_MAIN(block)\
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue())) {\
        block();\
    } else {\
        dispatch_async(dispatch_get_main_queue(), block);\
    }
#endif

#endif /* KKJSBridgeMacro_h */
