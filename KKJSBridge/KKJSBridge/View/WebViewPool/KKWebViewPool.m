//
//  KKWebViewPool.m
//  KKJSBridge
//
//  Created by karos li on 2019/8/16.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "KKWebViewPool.h"
#import "WKWebView+KKWebViewReusable.h"

@interface KKWebViewPool ()
@property (nonatomic, strong, readwrite) dispatch_semaphore_t lock;
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, NSMutableSet< __kindof WKWebView *> *> *dequeueWebViews;
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, NSMutableSet< __kindof WKWebView *> *> *enqueueWebViews;
@property (nonatomic, copy) void(^makeWebViewConfigurationBlock)(WKWebViewConfiguration *configuration);
@end

@implementation KKWebViewPool

+ (KKWebViewPool *)sharedInstance {
    static dispatch_once_t once;
    static KKWebViewPool *singleton;
    dispatch_once(&once, ^{
        singleton = [[KKWebViewPool alloc] init];
    });
    return singleton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _webViewMaxReuseCount = 5;
        _webViewMaxReuseTimes = NSIntegerMax;
        _webViewReuseLoadUrlStr = @"";
        
        _dequeueWebViews = @{}.mutableCopy;
        _enqueueWebViews = @{}.mutableCopy;
        _lock = dispatch_semaphore_create(1);
        //memory warning 时清理全部
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearAllReusableWebViews)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.dequeueWebViews removeAllObjects];
    [self.enqueueWebViews removeAllObjects];
    self.dequeueWebViews = nil;
    self.enqueueWebViews = nil;
}

#pragma mark - public method
- (__kindof WKWebView *)dequeueWebViewWithClass:(Class)webViewClass webViewHolder:(NSObject *)webViewHolder {
    if (![webViewClass isSubclassOfClass:[WKWebView class]]) {
#ifdef DEBUG
        NSLog(@"KKWebViewPool dequeue with invalid class:%@", webViewClass);
#endif
        return nil;
    }
    
    //auto recycle
    [self _tryCompactWeakHolderOfWebView];
    
    __kindof WKWebView *dequeueWebView = [self _getWebViewWithClass:webViewClass];
    dequeueWebView.holderObject = webViewHolder;
    return dequeueWebView;
}

- (void)makeWebViewConfiguration:(nullable void(^)(WKWebViewConfiguration *configuration))block {
    self.makeWebViewConfigurationBlock = block;
}

- (void)enqueueWebViewWithClass:(Class)webViewClass {
    if (![webViewClass isSubclassOfClass:[WKWebView class]]) {
#ifdef DEBUG
        NSLog(@"KKWebViewPool enqueue with invalid class:%@", webViewClass);
#endif
    }

    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    __kindof WKWebView *webView;
    NSString *webViewClassString = NSStringFromClass(webViewClass);
    
    if ([[_enqueueWebViews allKeys] containsObject:webViewClassString]) {
        NSMutableSet *viewSet =  [_enqueueWebViews objectForKey:webViewClassString];
        
        if (viewSet.count < [KKWebViewPool sharedInstance].webViewMaxReuseCount) {
            webView = [self generateInstanceWithWebViewClass:webViewClass];
            [viewSet addObject:webView];
        } else {
        }
    } else {
        NSMutableSet *viewSet = [[NSSet set] mutableCopy];
        webView = [self generateInstanceWithWebViewClass:webViewClass];
        [viewSet addObject:webView];
        [_enqueueWebViews setValue:viewSet forKey:webViewClassString];
    }
    dispatch_semaphore_signal(_lock);
}

- (void)enqueueWebView:(__kindof WKWebView *)webView {
    if (!webView) {
#ifdef DEBUG
        NSLog(@"KKWebViewPool enqueue with invalid view:%@", webView);
#endif
        return;
    }
    [webView removeFromSuperview];
    if (webView.reusedTimes >= [[KKWebViewPool sharedInstance] webViewMaxReuseTimes] || webView.invalid) {
        [self removeReusableWebView:webView];
    } else {
        [self _recycleWebView:webView];
    }
}

- (void)reloadAllReusableWebViews {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    for (NSMutableSet *viewSet in _enqueueWebViews.allValues) {
        for (__kindof WKWebView *webView in viewSet) {
            [webView componentViewWillEnterPool];
        }
    }
    dispatch_semaphore_signal(_lock);
}

- (void)clearAllReusableWebViews {
    //auto recycle
    [self _tryCompactWeakHolderOfWebView];

    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    [_enqueueWebViews removeAllObjects];
    dispatch_semaphore_signal(_lock);
}

- (void)removeReusableWebView:(__kindof WKWebView *)webView {
    if (!webView) {
        return;
    }

    if ([webView respondsToSelector:@selector(componentViewWillEnterPool)]) {
        [webView componentViewWillEnterPool];
    }
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);

    NSString *webViewClassString = NSStringFromClass([webView class]);

    if ([[_dequeueWebViews allKeys] containsObject:webViewClassString]) {
        NSMutableSet *viewSet =  [_dequeueWebViews objectForKey:webViewClassString];
        [viewSet removeObject:webView];
    }

    if ([[_enqueueWebViews allKeys] containsObject:webViewClassString]) {
        NSMutableSet *viewSet =  [_enqueueWebViews objectForKey:webViewClassString];
        [viewSet removeObject:webView];
    }
    dispatch_semaphore_signal(_lock);
}

- (void)clearAllReusableWebViewsWithClass:(Class)webViewClass {
    NSString *webViewClassString = NSStringFromClass(webViewClass);

    if (!webViewClassString || webViewClassString.length <= 0) {
        return;
    }

    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    if ([[_enqueueWebViews allKeys] containsObject:webViewClassString]) {
        [_enqueueWebViews removeObjectForKey:webViewClassString];
    }
    dispatch_semaphore_signal(_lock);
}

- (BOOL)containsReusableWebViewWithClass:(Class)webViewClass {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    NSString *webViewClassString = NSStringFromClass(webViewClass);
    
    BOOL contains = NO;
    if ([[_dequeueWebViews allKeys] containsObject:webViewClassString] || [[_enqueueWebViews allKeys] containsObject:webViewClassString]) {
        contains = YES;
    }
    dispatch_semaphore_signal(_lock);
    
    return contains;
}

#pragma mark - private method

- (void)_tryCompactWeakHolderOfWebView {
    NSDictionary *dequeueWebViewsTmp = _dequeueWebViews.copy;
    if (dequeueWebViewsTmp && dequeueWebViewsTmp.count > 0) {
        for (NSMutableSet *viewSet in dequeueWebViewsTmp.allValues) {
            NSSet *webViewSetTmp = viewSet.copy;
            for (__kindof WKWebView *webView in webViewSetTmp) {
                if (!webView.holderObject) {
                    [self enqueueWebView:webView];
                }
            }
        }
    }
}

- (void)_recycleWebView:(__kindof WKWebView *)webView {
    if (!webView) {
        return;
    }

    //进入回收池前清理
    if ([webView respondsToSelector:@selector(componentViewWillEnterPool)]) {
        [webView componentViewWillEnterPool];
    }

    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    NSString *webViewClassString = NSStringFromClass([webView class]);
    if ([[_dequeueWebViews allKeys] containsObject:webViewClassString]) {
        NSMutableSet *viewSet =  [_dequeueWebViews objectForKey:webViewClassString];
        [viewSet removeObject:webView];
    } else {
        dispatch_semaphore_signal(_lock);
#ifdef DEBUG
        NSLog(@"KKWebViewPool recycle invalid view");
#endif
    }
    
    if ([[_enqueueWebViews allKeys] containsObject:webViewClassString]) {
        NSMutableSet *viewSet =  [_enqueueWebViews objectForKey:webViewClassString];
        
        if (viewSet.count < [KKWebViewPool sharedInstance].webViewMaxReuseCount) {
            [viewSet addObject:webView];
        } else {
        }
    } else {
        NSMutableSet *viewSet = [[NSSet set] mutableCopy];
        [viewSet addObject:webView];
        [_enqueueWebViews setValue:viewSet forKey:webViewClassString];
    }

    dispatch_semaphore_signal(_lock);
}

- (__kindof WKWebView *)_getWebViewWithClass:(Class)webViewClass {
    NSString *webViewClassString = NSStringFromClass(webViewClass);

    if (!webViewClassString || webViewClassString.length <= 0) {
        return nil;
    }

    __kindof WKWebView *webView;

    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);

    if ([[_enqueueWebViews allKeys] containsObject:webViewClassString]) {
        NSMutableSet *viewSet =  [_enqueueWebViews objectForKey:webViewClassString];
        if (viewSet && viewSet.count > 0) {
            webView = [viewSet anyObject];
            if (![webView isMemberOfClass:webViewClass]) {
#ifdef DEBUG
                NSLog(@"KKWebViewPool webViewClassString: %@ already has webview of class:%@, params is %@", webViewClassString, NSStringFromClass([webView class]), NSStringFromClass(webViewClass));
#endif
                return nil;
            }
            [viewSet removeObject:webView];
        }
    }

    if (!webView) {
        webView = [self generateInstanceWithWebViewClass:webViewClass];
    }

    if ([[_dequeueWebViews allKeys] containsObject:webViewClassString]) {
        NSMutableSet *viewSet =  [_dequeueWebViews objectForKey:webViewClassString];
        [viewSet addObject:webView];
    } else {
        NSMutableSet *viewSet = [[NSSet set] mutableCopy];
        [viewSet addObject:webView];
        [_dequeueWebViews setValue:viewSet forKey:webViewClassString];
    }
    dispatch_semaphore_signal(_lock);

    //出回收池前初始化
    if ([webView respondsToSelector:@selector(componentViewWillLeavePool)]) {
        [webView componentViewWillLeavePool];
    }

    return webView;
}

- (__kindof WKWebView *)generateInstanceWithWebViewClass:(Class)webViewClass {
    WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    if (self.makeWebViewConfigurationBlock) {
        self.makeWebViewConfigurationBlock(config);
    }
    return [[webViewClass alloc] initWithFrame:CGRectZero configuration:config];
}

@end
