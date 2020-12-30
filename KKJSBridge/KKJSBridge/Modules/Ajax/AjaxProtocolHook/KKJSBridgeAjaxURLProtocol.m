//
//  KKJSBridgeAjaxURLProtocol.m
//  KKJSBridge
//
//  Created by karos li on 2020/6/20.
//

#import "KKJSBridgeAjaxURLProtocol.h"
#import <CFNetwork/CFNetwork.h>
#import <CoreFoundation/CoreFoundation.h>
#import <dlfcn.h>
#import "KKJSBridgeAjaxBodyHelper.h"
#import "KKJSBridgeXMLBodyCacheRequest.h"
#import "KKJSBridgeConfig.h"
#import "KKJSBridgeAjaxDelegate.h"
#import "KKJSBridgeSwizzle.h"
#import "KKJSBridgeWeakProxy.h"
#import "KKWebViewCookieManager.h"

typedef CFHTTPMessageRef (*KKJSBridgeURLResponseGetHTTPResponse)(CFURLRef response);

static NSString * const kKKJSBridgeNSURLProtocolKey = @"kKKJSBridgeNSURLProtocolKey";
static NSString * const kKKJSBridgeRequestId = @"KKJSBridge-RequestId";
static NSString * const kKKJSBridgeUrlRequestIdRegex = @"^.*?[&|\\?|%3f]?KKJSBridge-RequestId[=|%3d](\\d+).*?$";
static NSString * const kKKJSBridgeUrlRequestIdPairRegex = @"^.*?([&|\\?|%3f]?KKJSBridge-RequestId[=|%3d]\\d+).*?$";
static NSString * const kKKJSBridgeOpenUrlRequestIdRegex = @"^.*#%5E%5E%5E%5E(\\d+)%5E%5E%5E%5E$";
static NSString * const kKKJSBridgeOpenUrlRequestIdPairRegex = @"^.*(#%5E%5E%5E%5E\\d+%5E%5E%5E%5E)$";
static NSString * const kKKJSBridgeAjaxRequestHeaderAC = @"Access-Control-Request-Headers";
static NSString * const kKKJSBridgeAjaxResponseHeaderAC = @"Access-Control-Allow-Headers";

@interface KKJSBridgeAjaxURLProtocol () <NSURLSessionDelegate, KKJSBridgeAjaxDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *customTask;
@property (nonatomic, copy) NSString *requestId;
@property (nonatomic, copy) NSString *requestHTTPMethod;

@end

@implementation KKJSBridgeAjaxURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // 看看是否已经处理过了，防止无限循环
    if ([NSURLProtocol propertyForKey:kKKJSBridgeNSURLProtocolKey inRequest:request]) {
        return NO;
    }
    
    /**
     //?KKJSBridge-RequestId=159274166292276828
     链接有 RequestId
     */
    if ([request.URL.absoluteString containsString:kKKJSBridgeRequestId]) {
        return YES;
    }
  
    return NO;
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
    
    NSString *requestId;
    //?KKJSBridge-RequestId=159274166292276828
    if ([mutableReqeust.URL.absoluteString containsString:kKKJSBridgeRequestId]) {
        requestId = [self fetchRequestId:mutableReqeust.URL.absoluteString];
        // 移除临时的请求id键值对
        NSString *reqeustPair = [self fetchRequestIdPair:mutableReqeust.URL.absoluteString];
        if (reqeustPair) {
            NSString *absString = [mutableReqeust.URL.absoluteString stringByReplacingOccurrencesOfString:reqeustPair withString:@""];
            mutableReqeust.URL = [NSURL URLWithString:absString];
        }
    }
    
    self.requestId = requestId;
    self.requestHTTPMethod = mutableReqeust.HTTPMethod;
    
    /**
     统一的理解：NSHTTPCookieStorage 是唯一读取和存储 Cookie 的仓库，此时是可以不用保证 WKWebView Cookie 是否是最新的，只需要保证 NSHTTPCookieStorage 是最新的，并且每个请求从 NSHTTPCookieStorage 读取 Cookie 即可。因为既然已经代理了请求，就应该全权使用 NSHTTPCookieStorage 存储的 Cookie，来避免 WKWebView 的 Cookie 不是最新的问题。
     
     当有如下场景时，都可以统一同步 Cookie
     1、当 H5 是首次请求时，可以使用 NSHTTPCookieStorage 来同步下最新的 Cookie，因为首次请求之前，Cookie 的存储都是基于 NSHTTPCookieStorage。
     2、当 H5 是 ajax 异步请求时，可以使用 NSHTTPCookieStorage 来同步下最新的 Cookie，虽然异步请求可以通过 JS 注入的方式让 WKWebView 保持 Cookie 最新，但是无法保证 ajax 响应的 Set-Cookie 是最新的，而这部分 Set-Cookie 是存储在 NSHTTPCookieStorage 里面的。
     3、当 H5 是使用 document.cookie 获取 Cookie 并设置的 Cookie 请求头，此时是获取不到 HTTP Only Cookie 的，可以使用 NSHTTPCookieStorage 来同步下最新的 Cookie。
     
     虽然会产生重复设置，但是这里只要认准 NSHTTPCookieStorage 是唯一读取和存储 Cookie 的仓库事实就好了。
     唯一不能处理的是，有些 H5 会通过 document.cookie 去获取 cookie 并做一些逻辑的时候。目前可以通过 hook document.cookie.get 方法可以从 NSHTTPCookieStorage 读取最新的 Cookie 了。
     */
    [KKWebViewCookieManager syncRequestCookie:mutableReqeust];
    
    // 设置 body，针对没有 body 的方法，做一道拦截，不去设置 body，保持跟原生 WebView 一致的处理
    NSArray<NSString *> *methods = @[@"GET"];
    if (mutableReqeust.HTTPMethod.length > 0 && ![methods containsObject:mutableReqeust.HTTPMethod]) {
        NSDictionary *bodyReqeust = [KKJSBridgeXMLBodyCacheRequest getRequestBody:requestId];
        if (bodyReqeust) {
            // 从把缓存的 body 设置给 request
            [KKJSBridgeAjaxBodyHelper setBodyRequest:bodyReqeust toRequest:mutableReqeust];
        }
    }
    
    if (KKJSBridgeConfig.ajaxDelegateManager && [KKJSBridgeConfig.ajaxDelegateManager respondsToSelector:@selector(dataTaskWithRequest:callbackDelegate:)]) {
        // 实际请求代理外部网络库处理
        self.customTask = [KKJSBridgeConfig.ajaxDelegateManager dataTaskWithRequest:mutableReqeust callbackDelegate:self];
    } else {
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:(id<NSURLSessionDelegate>)[KKJSBridgeWeakProxy proxyWithTarget:self] delegateQueue:nil];
        self.customTask = [session dataTaskWithRequest:mutableReqeust];
    }
    
    [self.customTask resume];
}

- (void)stopLoading {
    if (self.customTask != nil) {
        [self.customTask  cancel];
        self.customTask = nil;
    }
    
    [self clearRequestBody];
}

- (void)clearRequestBody {
    /**
     参考
     全部的 method
     http://www.iana.org/assignments/http-methods/http-methods.xhtml
     https://stackoverflow.com/questions/41411152/how-many-http-verbs-are-there
     
     Http 1.1
     https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Methods
     
     HTTP Extensions WebDAV
     http://www.webdav.org/specs/rfc4918.html#http.methods.for.distributed.authoring
     */
    
    // 清除缓存
    // 针对有 body 的 method，才需要清除 body 缓存
    NSArray<NSString *> *methods = @[@"POST", @"PUT", @"DELETE", @"PATCH", @"LOCK", @"PROPFIND", @"PROPPATCH", @"SEARCH"];
    if (self.requestHTTPMethod.length > 0 && [methods containsObject:self.requestHTTPMethod]) {
        [KKJSBridgeXMLBodyCacheRequest deleteRequestBody:self.requestId];
    }
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    // 清除缓存
    [self clearRequestBody];
    
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

#pragma mark - KKJSBridgeAjaxDelegate - 处理来自外部网络库的数据
- (void)JSBridgeAjax:(id<KKJSBridgeAjaxDelegate>)ajax didReceiveResponse:(NSURLResponse *)response {
    if (!response) {
        // 兜底处理
        response = [[NSURLResponse alloc] initWithURL:self.request.URL MIMEType:@"application/octet-stream" expectedContentLength:0 textEncodingName:@"utf-8"];
    }
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
}

- (void)JSBridgeAjax:(id<KKJSBridgeAjaxDelegate>)ajax didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)JSBridgeAjax:(id<KKJSBridgeAjaxDelegate>)ajax didCompleteWithError:(NSError * _Nullable)error {
    // 清除缓存
    [self clearRequestBody];
    
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

#pragma mark - 请求id相关
- (NSString *)fetchRequestId:(NSString *)url {
    return [self fetchMatchedTextFromUrl:url withRegex:kKKJSBridgeUrlRequestIdRegex];
}

- (NSString *)fetchRequestIdPair:(NSString *)url {
    return [self fetchMatchedTextFromUrl:url withRegex:kKKJSBridgeUrlRequestIdPairRegex];
}

- (NSString *)fetchMatchedTextFromUrl:(NSString *)url withRegex:(NSString *)regexString {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:NULL];
    NSArray *matches = [regex matchesInString:url options:0 range:NSMakeRange(0, url.length)];
    NSString *content;
    for (NSTextCheckingResult *match in matches) {
        for (int i = 0; i < [match numberOfRanges]; i++) {
            //以正则中的(),划分成不同的匹配部分
            content = [url substringWithRange:[match rangeAtIndex:i]];
            if (i == 1) {
                return content;
            }
        }
    }
    
    return content;
}

+ (BOOL)validateRequestId:(NSString *)url withRegex:(NSString *)regexString
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regexString];
    return [predicate evaluateWithObject:url];
}

#pragma mark - 私有方法
- (NSURLResponse *)appendRequestIdToResponseHeader:(NSURLResponse *)response {
    if ([response isKindOfClass:NSHTTPURLResponse.class]) {
        NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
        NSMutableDictionary *headers = [res.allHeaderFields mutableCopy];
        if (!headers) {
            headers = [NSMutableDictionary dictionary];
        }
        
        NSMutableString *string = [headers[kKKJSBridgeAjaxResponseHeaderAC] mutableCopy];
        if (string) {
            [string appendFormat:@",%@", kKKJSBridgeRequestId];
        } else {
            string = [kKKJSBridgeRequestId mutableCopy];
        }
        headers[kKKJSBridgeAjaxResponseHeaderAC] = [string copy];
        headers[@"Access-Control-Allow-Credentials"] = @"true";
        headers[@"Access-Control-Allow-Origin"] = @"*";
        headers[@"Access-Control-Allow-Methods"] = @"OPTIONS,GET,POST,PUT,DELETE";
        
        NSHTTPURLResponse *updateRes = [[NSHTTPURLResponse alloc] initWithURL:res.URL statusCode:res.statusCode HTTPVersion:[self getHttpVersionFromResponse:res] headerFields:[headers copy]];
        response = updateRes;
    }
    
    return response;
}

- (NSString *)getHttpVersionFromResponse:(NSURLResponse *)response {
    NSString *version;
    // 获取CFURLResponseGetHTTPResponse的函数实现
    NSString *funName = @"CFURLResponseGetHTTPResponse";
    KKJSBridgeURLResponseGetHTTPResponse originURLResponseGetHTTPResponse = dlsym(RTLD_DEFAULT, [funName UTF8String]);

    SEL theSelector = NSSelectorFromString(@"_CFURLResponse");
    if ([response respondsToSelector:theSelector] &&
        NULL != originURLResponseGetHTTPResponse) {
        // 获取NSURLResponse的_CFURLResponse
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        CFTypeRef cfResponse = CFBridgingRetain([response performSelector:theSelector]);
        #pragma clang diagnostic pop
        
        if (NULL != cfResponse) {
            // 将CFURLResponseRef转化为CFHTTPMessageRef
            CFHTTPMessageRef message = originURLResponseGetHTTPResponse(cfResponse);
            // 获取http协议版本
            CFStringRef cfVersion = CFHTTPMessageCopyVersion(message);
            if (NULL != cfVersion) {
                version = (__bridge NSString *)cfVersion;
                CFRelease(cfVersion);
            }
            CFRelease(cfResponse);
        }
    }

    // 获取失败的话则设置一个默认值
    if (nil == version || ![version isKindOfClass:NSString.class] || version.length == 0) {
        version = @"HTTP/1.1";
    }

    return version;
}

@end
