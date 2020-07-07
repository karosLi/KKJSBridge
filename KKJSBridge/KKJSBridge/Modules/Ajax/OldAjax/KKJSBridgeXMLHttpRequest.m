//
//  KKJSBridgeXMLHttpRequest.m
//  KKJSBridge
//
//  Created by karos li on 2019/7/23.
//  Copyright © 2019 karosli. All rights reserved.
//

#import "KKJSBridgeXMLHttpRequest.h"
#import "KKJSBridgeMacro.h"
#import "KKJSBridgeEngine.h"
#import "KKJSBridgeJSExecutor.h"
#import "KKJSBridgeLogger.h"
#import "KKJSBridgeWeakProxy.h"
#import "KKJSBridgeAjaxDelegate.h"
#import "KKJSBridgeURLRequestSerialization.h"
#import "KKJSBridgeFormDataFile.h"

/**
 https://developer.mozilla.org/zh-CN/docs/Web/API/XMLHttpRequest
 
 readyState:0 status:200 statusText:
 readyState:1 status:200 statusText:
 readyState:2 status:200 statusText:OK
 readyState:3 status:200 statusText:OK
 readyState:4 status:200 statusText:OK
 **/

typedef NS_ENUM(NSInteger, KKJSBridgeXMLHttpRequestState) {
    KKJSBridgeXMLHttpRequestStateUnset = 0, // 初始化，但尚未调用 open() 方法
    KKJSBridgeXMLHttpRequestStateOpened, // open() 方法已经被调用
    KKJSBridgeXMLHttpRequestStateHeaderReceived, // send() 方法已经被调用，并且头部和状态已经可获得
    KKJSBridgeXMLHttpRequestStateLoading, // 下载中； responseText 属性已经包含部分数据
    KKJSBridgeXMLHttpRequestStateDone, // 下载操作已完成
};

typedef NS_ENUM(NSInteger, KKJSBridgeXMLHttpRequestStatus) {
    KKJSBridgeXMLHttpRequestStatusUnset = 200,
    KKJSBridgeXMLHttpRequestStatusOpened = 200,
    KKJSBridgeXMLHttpRequestStatusHeaderReceived = 200,
    KKJSBridgeXMLHttpRequestStatusLoading = 200,
    KKJSBridgeXMLHttpRequestStatusDone = 200
};

static NSString * const KKJSBridgeXMLHttpRequestStatusTextInit = @"";
static NSString * const KKJSBridgeXMLHttpRequestStatusTextOK = @"OK";

@interface KKJSBridgeXMLHttpRequest()<NSURLSessionDelegate, KKJSBridgeAjaxDelegate>

@property (nonatomic, weak) KKJSBridgeEngine *engine;
@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, strong) NSNumber *objectId;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSMutableURLRequest *request;
@property (nonatomic, strong) NSString *responseCharset; // for example: gbk, gb2312, etc.
@property (nonatomic, strong) NSMutableData *receiveData;

@property (nonatomic, copy) NSDictionary *headerProperties;
@property (nonatomic, assign) BOOL aborted;
@property (nonatomic, assign) KKJSBridgeXMLHttpRequestState state;

@property (nonatomic, strong) NSHTTPURLResponse *httpResponse;
@property (nonatomic, copy) NSString *responseText;

@property (nonatomic, strong) dispatch_semaphore_t lock;

@end

@implementation KKJSBridgeXMLHttpRequest

- (instancetype)initWithObjectId:(NSNumber *)objectId engine:(KKJSBridgeEngine *)engine {
    if (self = [super init]) {
        _objectId = objectId;
        _engine = engine;
        _webView = engine.webView;
        _state = KKJSBridgeXMLHttpRequestStateUnset;
        _lock = dispatch_semaphore_create(1);
    }
    
    return self;
}

- (void)dealloc {
    [self abort];
    self.receiveData = nil;
    self.delegate = nil;
    self.webView = nil;
}

- (void)createHttpRequestWithMethod:(NSString *)method url:(NSString *)url {
    if (method) {
        NSURL *urlObj = [[NSURL alloc] initWithString:url];
        self.request = [[NSMutableURLRequest alloc] initWithURL:urlObj cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
        if ([method caseInsensitiveCompare:@"GET"] == NSOrderedSame) {
            self.request.HTTPMethod = @"GET";
        } else if ([method caseInsensitiveCompare:@"POST"] == NSOrderedSame) {
            self.request.HTTPMethod = @"POST";
        } else if ([method caseInsensitiveCompare:@"HEAD"] == NSOrderedSame) {
            self.request.HTTPMethod = @"HEAD"; // 获取资源的首部元信息
        } else if ([method caseInsensitiveCompare:@"OPTIONS"] == NSOrderedSame) {
            self.request.HTTPMethod = @"OPTIONS"; // 一般用于跨域预检查
        } else if ([method caseInsensitiveCompare:@"DELETE"] == NSOrderedSame) {
            self.request.HTTPMethod = @"DELETE"; // 删除指定资源
        } else {
            [self returnError:405 statusText:@"Method Not Allowed"];
            [self notifyFetchFailed];
        }
    } else {
        [self returnError:405 statusText:@"Method Not Allowed"];
        [self notifyFetchFailed];
    }
    
    // UNSET 状态不用回调给 H5
}

#pragma mark - ajax method
/**
 * The reason that userAgent and referer are not set in the constructor is
 * that XMLHttpRequest.constructor in the JS layer may be called only once,
 * while XMLHttpRequest.open may be called multiple times. In this case, we
 * still have to create a brand new XMLHttpRequest object internally in the
 * Java layer, in which case we have no way of acquiring userAgent of the
 * browser and referer of the current request, but JS#XMLHttpRequest.open
 * can send them to us here.
 *
 * @param method    - GET/POST/HEAD
 * @param url       - the url to request
 * @param userAgent - User-Agent of the browser(currently WebView)
 * @param referer   - referer of the current request
 */
- (void)open:(NSString *)method url:(NSString *)url userAgent:(NSString *)userAgent referer:(NSString *)referer {
    [self createHttpRequestWithMethod:method url:url];
    if (self.request) {
        [self.request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
        if (referer && ![referer isKindOfClass:[NSNull class]]) {
            [self.request setValue:referer forHTTPHeaderField:@"Referer"];
        }
        
        [self returnReadySate:KKJSBridgeXMLHttpRequestStateOpened];
    }
}

/**
 * for GET and HEAD start data transmission(sending the request and reading
 * the response)
 */
- (void)send {
    // open() must be called before calling send()
    if (!self.request)
        return;
    
    self.aborted = NO;
    
    if (KKJSBridgeConfig.ajaxDelegateManager && [KKJSBridgeConfig.ajaxDelegateManager respondsToSelector:@selector(dataTaskWithRequest:callbackDelegate:)]) {
        // 实际请求代理外部网络库处理
        self.dataTask = [KKJSBridgeConfig.ajaxDelegateManager dataTaskWithRequest:self.request callbackDelegate:self];
    } else {
        NSOperationQueue *queue = [NSOperationQueue new];
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:(id<NSURLSessionDelegate>)[KKJSBridgeWeakProxy proxyWithTarget:self] delegateQueue:queue]; // 防止内存泄露
        
        self.receiveData = [[NSMutableData alloc] init];
        self.dataTask = [session dataTaskWithRequest:self.request];
    }
    
    [self.dataTask resume];
}

- (void)send:(id)data {
    if (!self.request)
        return;
    
    NSData *actualData;
    if ([data isKindOfClass:NSDictionary.class]) {
        // application/json
        actualData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
    } else if ([data isKindOfClass:NSString.class]) {
        // application/x-www-form-urlencoded
        // name1=value1&name2=value2
        actualData = [data dataUsingEncoding:NSUTF8StringEncoding];
    } else {
        actualData = data;
    }
    
    KKJS_LOCK(_lock);
    if (actualData) {
        self.request.HTTPBody = actualData;
    }
    
    [self send];
    KKJS_UNLOCK(_lock);
}

- (void)sendFormData:(NSDictionary *)params withFileDatas:(NSArray<KKJSBridgeFormDataFile *> *)fileDatas {
    KKJSBridgeURLRequestSerialization *serializer = [KKJSBridgeXMLHttpRequest urlRequestSerialization];
    [serializer multipartFormRequestWithRequest:self.request parameters:params constructingBodyWithBlock:^(id<KKJSBridgeMultipartFormData>  _Nonnull formData) {
        for (KKJSBridgeFormDataFile *fileData in fileDatas) {
            [formData appendPartWithFileData:fileData.data name:fileData.key fileName:fileData.fileName mimeType:fileData.type];
        }
    } error:nil];
    [self send];
}

- (void)setRequestHeader:(NSString *)headerName headerValue:(NSString *)headerValue {
    [self.request setValue:headerValue forHTTPHeaderField:headerName];
}

// "text/html;charset=gbk", "gbk" will be extracted, others will be ignored.
- (void)readCharset:(NSString *)mimeType {
    NSArray *arr = [mimeType componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@";="]];
    for (int i = 0; i < arr.count; ++i){
        NSString *s = [arr objectAtIndex:i];
        s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if ([s caseInsensitiveCompare:@"charset"] == NSOrderedSame) {
            if (i + 1 < arr.count) {
                self.responseCharset = [arr objectAtIndex:i + 1] ;
            }
            break;
        }
    }
}

- (void)overrideMimeType:(NSString *)mimeType {
    /**
     顾名思义，该方法用于浏览器重写服务器响应头返回的 contentType 中的 mimeType (例如:text/html;charset=utf-8)
     
     根据在 chrome 里 https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest 链接下的控制台上的 ajax 运行结果来看。
     1、响应头里 Content-Type 始终返回的是服务器的值（text/html;charset=utf-8）。
     2、ajax 请求时设置的 mimeType (image/jpeg;charset=ASCII)，媒体类型是不起作用的，只有编码部分是起作用的。
     
     总结：
     1、只有在服务器无法返回 Content-Type 数据类型时，才使用 overrideMimeType 方法，而现代服务器基本上都会返回 Content-Type。
     2、针对这个 overrideMimeType，端上的代码目前只需要处理字符编码部分的逻辑。
     
     测试demo：
     var xhr = new XMLHttpRequest(),
     method = "GET",
     url = "https://developer.mozilla.org/";
     xhr.overrideMimeType("image/jpeg;charset=ASCII");
     xhr.open(method, url, true);
     xhr.onreadystatechange = function () {
        if(xhr.readyState === 4 && xhr.status === 200) {
            console.log(xhr.responseText);
        }
     };
     xhr.send();
     
     执行后返回的结果如下：
     xhr.overrideMimeType("image/jpeg;charset=utf-8");
     <title>MDN Web 文档</title>
     
     xhr.overrideMimeType("image/jpeg;charset=ASCII");
     <title>MDN Web æ–‡æ¡£</title>
     
     */
    [self readCharset:mimeType];
}

- (BOOL)isOpened {
    return self.state == KKJSBridgeXMLHttpRequestStateOpened;
}

- (void)abort {
    if (!self.aborted && self.state != KKJSBridgeXMLHttpRequestStateDone) {
        self.aborted = YES;
        [self cancelTask];
    }
}

- (void)cancelTask {
    if (self.dataTask != nil) {
        [self.dataTask  cancel];
        self.dataTask = nil;
    }
}

#pragma mark - 处理来自组件内网络逻辑的数据
#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
#ifdef DEBUG
    NSLog(@"ajax didBecomeInvalidWithError %@", error.localizedDescription);
#endif
}

#pragma mark -- NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    completionHandler(NSURLSessionResponseAllow);
    [self handleReceivedResponse:response];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.receiveData appendData:data];
    [self returnReadySate:KKJSBridgeXMLHttpRequestStateLoading];
}

#pragma mark -- NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    NSData *data = nil;
    if (!error && self.receiveData) {
        data = [self.receiveData copy];
        // 如果不使用了，可以释放引用，这样会释放些内存
        self.receiveData = nil;
    }
    [self handleCompletion:data error:error];
}

#pragma mark - KKJSBridgeAjaxDelegate - 处理来自外部网络库的数据

- (void)JSBridgeAjax:(id<KKJSBridgeAjaxDelegate>)ajax didReceiveResponse:(NSURLResponse *)response {
    [self handleReceivedResponse:response];
}

- (void)JSBridgeAjax:(id<KKJSBridgeAjaxDelegate>)ajax didReceiveData:(NSData *)data {
    [self.receiveData appendData:data];
    [self returnReadySate:KKJSBridgeXMLHttpRequestStateLoading];
}

- (void)JSBridgeAjax:(id<KKJSBridgeAjaxDelegate>)ajax didCompleteWithError:(NSError * _Nullable)error {
    NSData *data = nil;
    if (!error && self.receiveData) {
        data = [self.receiveData copy];
        // 如果不使用了，可以释放引用，这样会释放些内存
        self.receiveData = nil;
    }
    [self handleCompletion:data error:error];
}

#pragma mark - 统一处理请求头和回来的数据
- (void)handleReceivedResponse:(NSURLResponse *)response {
    self.httpResponse = (NSHTTPURLResponse *)response;
    [self returnReadySate:KKJSBridgeXMLHttpRequestStateHeaderReceived];
}

- (void)handleCompletion:(NSData * _Nullable)responseData error:(NSError * _Nullable)error {
    if (error == nil) {
        // 处理响应编码方式
        NSString *textEncodingName = self.responseCharset ? self.responseCharset : self.httpResponse.textEncodingName;
        NSStringEncoding stringEncoding = NSUTF8StringEncoding;
        if (textEncodingName) {
            CFStringEncoding encoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)textEncodingName);
            if (encoding != kCFStringEncodingInvalidId) {
                stringEncoding = CFStringConvertEncodingToNSStringEncoding(encoding);
            }
        }
        
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:stringEncoding];
        self.responseText = responseString;
        [self returnReadySate:KKJSBridgeXMLHttpRequestStateDone];
        [self notifyFetchComplete];
    } else {
#ifdef DEBUG
        NSLog(@"ajax didCompleteWithError %@ %@", self.request.URL.absoluteString, error.localizedDescription);
#endif
        [self returnError:self.httpResponse.statusCode statusText:error.localizedDescription];
        [self notifyFetchFailed];
    }
}

#pragma mark - js result handle
- (void)returnError:(NSInteger)statusCode statusText:(NSString *)statusText {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    properties[@"id"] = self.objectId;
    properties[@"readyState"] = @(KKJSBridgeXMLHttpRequestStateDone);
    properties[@"status"] = @(statusCode);
    properties[@"statusText"] = statusText;
    
    [KKJSBridgeXMLHttpRequest evaluateJSToSetAjaxProperties:properties inWebView:self.webView];
    self.state = KKJSBridgeXMLHttpRequestStateDone;
    [self cancelTask];
}

- (NSDictionary *)returnReadySate:(KKJSBridgeXMLHttpRequestState)readyState {
    if (self.aborted)
        return nil;
    
    KKJSBridgeXMLHttpRequestStatus status = KKJSBridgeXMLHttpRequestStatusUnset;
    NSString *statusText = KKJSBridgeXMLHttpRequestStatusTextInit;
    // 设置默认状态
    if (readyState == KKJSBridgeXMLHttpRequestStateUnset) {
        status = KKJSBridgeXMLHttpRequestStatusUnset;
        statusText = KKJSBridgeXMLHttpRequestStatusTextInit;
    } else if (readyState == KKJSBridgeXMLHttpRequestStateOpened) {
        status = KKJSBridgeXMLHttpRequestStatusOpened;
        statusText = KKJSBridgeXMLHttpRequestStatusTextInit;
    } else if (readyState == KKJSBridgeXMLHttpRequestStateHeaderReceived) {
        status = KKJSBridgeXMLHttpRequestStatusHeaderReceived;
        statusText = KKJSBridgeXMLHttpRequestStatusTextOK;
    } else if (readyState == KKJSBridgeXMLHttpRequestStateLoading) {
        status = KKJSBridgeXMLHttpRequestStatusLoading;
        statusText = KKJSBridgeXMLHttpRequestStatusTextOK;
    } else if (readyState == KKJSBridgeXMLHttpRequestStateDone) {
        status = KKJSBridgeXMLHttpRequestStatusDone;
        statusText = KKJSBridgeXMLHttpRequestStatusTextOK;
    }
    
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    properties[@"id"] = self.objectId;
    properties[@"readyState"] = @(readyState);
    properties[@"status"] = @(status);
    properties[@"statusText"] = statusText;
    
    if (readyState == KKJSBridgeXMLHttpRequestStateHeaderReceived && !self.headerProperties && self.httpResponse) { // 如果响应头没有保存过，那么需要解析响应头，并进行保存
        NSString *contentType = [self.httpResponse.allHeaderFields objectForKey:@"Content-Type"];
        if (contentType != nil && contentType.length > 0)
            [self readCharset:contentType];
        
        NSInteger status = self.httpResponse.statusCode;
        NSString *statusText = [NSHTTPURLResponse localizedStringForStatusCode:status];
        
        // 状态会被响应头重写
        properties[@"status"] = @(status);
        properties[@"statusText"] = statusText;
        properties[@"headers"] = self.httpResponse.allHeaderFields;
        self.headerProperties = properties;
    }
    
    if (readyState == KKJSBridgeXMLHttpRequestStateDone) {
        // 状态会被响应头重写
        properties[@"status"] = self.headerProperties[@"status"] ? self.headerProperties[@"status"] : properties[@"status"];
        properties[@"statusText"] = self.headerProperties[@"statusText"] ? self.headerProperties[@"statusText"] : properties[@"statusText"];
        properties[@"responseText"] = self.responseText;
        properties[@"headers"] = self.headerProperties[@"headers"];
        [KKJSBridgeLogger log:@"Ajax Callback" module:@"_XHR" method:@"setProperties" data:properties];
    }
    
    [KKJSBridgeXMLHttpRequest evaluateJSToSetAjaxProperties:properties inWebView:self.webView];
    self.state = readyState;
    return properties;
}

#pragma mark - KKJSBridgeModuleXMLHttpRequestDelegate 通知给 ajax 模块分发者，当前请求的状态
- (void)notifyFetchComplete {
    if ([self.delegate respondsToSelector:@selector(notifyDispatcherFetchComplete:)]) {
        [self.delegate notifyDispatcherFetchComplete:self];
    }
}

- (void)notifyFetchFailed {
    if ([self.delegate respondsToSelector:@selector(notifyDispatcherFetchFailed:)]) {
        [self.delegate notifyDispatcherFetchFailed:self];
    }
}

#pragma mark - util
+ (void)evaluateJSToDeleteAjaxCache:(NSNumber *)objectId inWebView:(WKWebView *)webView {
    [KKJSBridgeJSExecutor evaluateJavaScriptFunction:@"window._XHR.deleteObject" withNumber:objectId inWebView:webView completionHandler:nil];
}

+ (void)evaluateJSToSetAjaxProperties:(NSDictionary *)json inWebView:(WKWebView *)webView {
    [KKJSBridgeJSExecutor evaluateJavaScriptFunction:@"window._XHR.setProperties" withJson:json inWebView:webView completionHandler:nil];
}

#pragma mark - KKJSBridgeURLRequestSerialization

+ (KKJSBridgeURLRequestSerialization *)urlRequestSerialization {
    static KKJSBridgeURLRequestSerialization *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [KKJSBridgeURLRequestSerialization new];
    });
    
    return instance;
}

@end
