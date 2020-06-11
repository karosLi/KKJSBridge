//
//  WKWebView+KKWebViewExtension.m
//  KKJSBridge
//
//  直接使用的是 HybridPageKit/WKWebView + WKWebView + HPKExtension
//
//  Created by karos li on 2019/7/29.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "WKWebView+KKWebViewExtension.h"
#import <objc/runtime.h>

@implementation WKWebView (KKWebViewExtension)

#pragma mark - UA

+ (void)configCustomUAWithType:(KKWebViewConfigUAType)type
                      UAString:(NSString *)customString {
    if (!customString || customString.length <= 0) {
        NSLog(@"WKWebView (SyncConfigUA) config with invalid string");
        return;
    }
    
    if (type == KKWebViewConfigUATypeReplace) {
        NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:customString, @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    } else if (type == KKWebViewConfigUATypeAppend) {
        
        //同步获取webview UserAgent
        NSString *originalUserAgent;
        WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero];
        SEL privateUASel = NSSelectorFromString([[NSString alloc] initWithFormat:@"%@%@%@",@"_",@"user",@"Agent"]);
        if ([webView respondsToSelector:privateUASel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            originalUserAgent = [webView performSelector:privateUASel];
#pragma clang diagnostic pop
        }
        
        NSString *appUserAgent = [NSString stringWithFormat:@"%@ %@", originalUserAgent ?: @"", customString];
        NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:appUserAgent, @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    } else {
        NSLog(@"WKWebView (SyncConfigUA) config with invalid type :%@", @(type));
    }
}

#pragma mark - clear webview cache

static inline void clearWebViewCacheFolderByType(NSString *cacheType) {
    static dispatch_once_t once;
    static NSDictionary *cachePathMap = nil;
    dispatch_once(&once,
                  ^{
                      NSString *bundleId = [NSBundle mainBundle].infoDictionary[(NSString *)kCFBundleIdentifierKey];
                      NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
                      NSString *storageFileBasePath = [libraryPath stringByAppendingPathComponent:
                                                       [NSString stringWithFormat:@"WebKit/%@/WebsiteData/", bundleId]];
                      cachePathMap = @{ @"WKWebsiteDataTypeCookies":
                                            [libraryPath stringByAppendingPathComponent:@"Cookies/Cookies.binarycookies"],
                                        @"WKWebsiteDataTypeLocalStorage":
                                            [storageFileBasePath stringByAppendingPathComponent:@"LocalStorage"],
                                        @"WKWebsiteDataTypeIndexedDBDatabases":
                                            [storageFileBasePath stringByAppendingPathComponent:@"IndexedDB"],
                                        @"WKWebsiteDataTypeWebSQLDatabases":
                                            [storageFileBasePath stringByAppendingPathComponent:@"WebSQL"] };
                  });
    NSString *filePath = cachePathMap[cacheType];
    if (filePath && filePath.length > 0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if (error) {
                NSLog(@"removed file fail: %@ ,error %@", [filePath lastPathComponent], error);
            }
        }
    }
}

+ (void)safeClearAllCacheIncludeiOS8:(BOOL)includeiOS8 {
    if (@available(iOS 9, *)) {
        NSSet *websiteDataTypes = [NSSet setWithArray:@[
                                                        WKWebsiteDataTypeMemoryCache,
                                                        WKWebsiteDataTypeSessionStorage,
                                                        WKWebsiteDataTypeDiskCache,
                                                        WKWebsiteDataTypeOfflineWebApplicationCache,
                                                        WKWebsiteDataTypeCookies,
                                                        WKWebsiteDataTypeLocalStorage,
                                                        WKWebsiteDataTypeIndexedDBDatabases,
                                                        WKWebsiteDataTypeWebSQLDatabases
                                                        ]];
        
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes
                                                   modifiedSince:date
                                               completionHandler:^{
                                                   NSLog(@"Clear All Cache Done");
                                               }];
    } else {
        if (includeiOS8) {
            NSSet *websiteDataTypes = [NSSet setWithArray:@[
                                                            @"WKWebsiteDataTypeCookies",
                                                            @"WKWebsiteDataTypeLocalStorage",
                                                            @"WKWebsiteDataTypeIndexedDBDatabases",
                                                            @"WKWebsiteDataTypeWebSQLDatabases"
                                                            ]];
            for (NSString *type in websiteDataTypes) {
                clearWebViewCacheFolderByType(type);
            }
        }
    }
}

@end
