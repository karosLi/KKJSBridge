//
//  WKWebView+KKWebViewReusable.m
//  KKJSBridge
//
//  Created by karos li on 2019/8/16.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "WKWebView+KKWebViewReusable.h"
#import <objc/runtime.h>
#import "KKWebViewPool.h"
#import "WKWebView+KKJSBridgeEngine.h"

@interface _KKWebViewWeakWrapper : NSObject
@property(nonatomic, weak, readwrite)NSObject *weakObj;
@end
@implementation _KKWebViewWeakWrapper
@end

@implementation WKWebView (KKWebViewReusable)

#pragma mark -

- (void)setHolderObject:(NSObject *)holderObject {
    _KKWebViewWeakWrapper *wrapObj = objc_getAssociatedObject(self, @selector(setHolderObject:));
    if (wrapObj) {
        wrapObj.weakObj = holderObject;
    }else{
        wrapObj = [[_KKWebViewWeakWrapper alloc] init];
        wrapObj.weakObj = holderObject;
        objc_setAssociatedObject(self, @selector(setHolderObject:), wrapObj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (NSObject *)holderObject {
    _KKWebViewWeakWrapper *wrapObj = objc_getAssociatedObject(self, @selector(setHolderObject:));
    return wrapObj.weakObj;
}

- (void)setReusedTimes:(NSInteger)reusedTimes {
    NSNumber *reusedTimesNum = @(reusedTimes);
    objc_setAssociatedObject(self, @selector(setReusedTimes:), reusedTimesNum, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)reusedTimes {
    NSNumber *reusedTimesNum = objc_getAssociatedObject(self, @selector(setReusedTimes:));
    return [reusedTimesNum integerValue];
}

- (void)setInvalid:(BOOL)invalid {
    objc_setAssociatedObject(self, @selector(setInvalid:), @(invalid), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)invalid {
    NSNumber *invalidNum = objc_getAssociatedObject(self, @selector(setInvalid:));
    return invalidNum.boolValue;
}

#pragma mark -

- (void)componentViewWillLeavePool {
    self.reusedTimes += 1;
    [self _clearBackForwardList];
}

- (void)componentViewWillEnterPool {
    self.holderObject = nil;
    self.kk_engine = nil;
    self.scrollView.delegate = nil;
    self.scrollView.scrollEnabled = YES;
    [self stopLoading];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self evaluateJavaScript:@"window.sessionStorage.clear();" completionHandler:nil];
    [self.configuration.userContentController removeAllUserScripts];
    NSString *reuseLoadUrl = [[KKWebViewPool sharedInstance] webViewReuseLoadUrlStr];
    if (reuseLoadUrl && reuseLoadUrl.length > 0) {
        [self loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:reuseLoadUrl]]];
    } else {
        [self loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@""]]];
    }
}

#pragma mark - clear backForwardList

- (void)_clearBackForwardList {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL sel = NSSelectorFromString([NSString stringWithFormat:@"%@%@%@%@", @"_re", @"moveA", @"llIte", @"ms"]);
    if ([self.backForwardList respondsToSelector:sel]) {
        [self.backForwardList performSelector:sel];
    }
#pragma clang diagnostic pop
}

@end
