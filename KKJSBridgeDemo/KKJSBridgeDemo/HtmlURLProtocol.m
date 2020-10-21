//
//  HtmlURLProtocol.m
//  KKJSBridgeDemo
//
//  Created by karos li on 2020/7/22.
//  Copyright © 2020 karosli. All rights reserved.
//

#import "HtmlURLProtocol.h"

static NSString * const kKKJSBridgeNSURLProtocolKey = @"kKKJSBridgeNSURLProtocolKey1";

@interface HtmlURLProtocol () <NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *customTask;
@property (nonatomic, copy) NSString *requestId;
@property (nonatomic, copy) NSString *requestHTTPMethod;

@end

@implementation HtmlURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // 看看是否已经处理过了，防止无限循环
    if ([NSURLProtocol propertyForKey:kKKJSBridgeNSURLProtocolKey inRequest:request]) {
        return NO;
    }
  
    NSLog(@"HtmlURLProtocol %@", request.URL.absoluteString);
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (instancetype)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client {
    self = [super initWithRequest:request cachedResponse:cachedResponse client:client];
    if (self) {
        
    }
    return self;
}

- (void)startLoading {
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    //给我们处理过的请求设置一个标识符, 防止无限循环,
    [NSURLProtocol setProperty:@YES forKey:kKKJSBridgeNSURLProtocolKey inRequest:mutableReqeust];
    
    // 处理离线资源，或者替换资源的样式
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    self.customTask = [session dataTaskWithRequest:mutableReqeust];
    [self.customTask resume];
}

- (void)stopLoading {
    if (self.customTask != nil) {
        [self.customTask  cancel];
        self.customTask = nil;
    }
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

@end
