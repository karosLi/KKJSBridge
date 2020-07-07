//
//  KKJSBridgeAjaxURLProtocol.m
//  KKJSBridge
//
//  Created by karos li on 2020/6/20.
//

#import "KKJSBridgeAjaxURLProtocol.h"
#import "KKJSBridgeXMLBodyCacheRequest.h"
#import "KKJSBridgeURLRequestSerialization.h"
#import "KKJSBridgeFormDataFile.h"
#import "KKJSBridgeConfig.h"
#import "KKJSBridgeAjaxDelegate.h"

static NSString * const kKKJSBridgeNSURLProtocolKey = @"kKKJSBridgeNSURLProtocolKey";
static NSString * const kKKJSBridgeRequestId = @"KKJSBridge-RequestId";

@interface KKJSBridgeAjaxURLProtocol () <NSURLSessionDelegate, KKJSBridgeAjaxDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *customTask;
@property (nonatomic, copy) NSString *requestId;

@end

@implementation KKJSBridgeAjaxURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSDictionary *headers = request.allHTTPHeaderFields;
    // 请求头或者链接有 RequestId
    if ([headers.allKeys containsObject:kKKJSBridgeRequestId] || [request.URL.absoluteString containsString:kKKJSBridgeRequestId]) {
        // 看看是否已经处理过了，防止无限循环
        if ([NSURLProtocol propertyForKey:kKKJSBridgeNSURLProtocolKey inRequest:request]) {
            return NO;
        }
        
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
    
    NSDictionary *headers = mutableReqeust.allHTTPHeaderFields;
    NSString *requestId;
    if ([headers.allKeys containsObject:kKKJSBridgeRequestId]) {
        requestId = headers[kKKJSBridgeRequestId];
        // 移除临时的请求头
        [mutableReqeust setValue:nil forHTTPHeaderField:kKKJSBridgeRequestId];
    } else {
        //?KKJSBridge-RequestId=1592741662922_76828
        NSDictionary *queryParams = [self queryParams:mutableReqeust.URL.absoluteString];
        requestId = queryParams[kKKJSBridgeRequestId];
    }
    
    NSDictionary *bodyReqeust = [KKJSBridgeXMLBodyCacheRequest getRequestBody:requestId];
    if (bodyReqeust) {
        // 从把缓存的 body 设置给 request
        [self setBodyRequest:bodyReqeust toRequest:mutableReqeust];
        
        // 发送请求
        self.requestId = requestId;
        
        if (KKJSBridgeConfig.ajaxDelegateManager && [KKJSBridgeConfig.ajaxDelegateManager respondsToSelector:@selector(dataTaskWithRequest:callbackDelegate:)]) {
            // 实际请求代理外部网络库处理
            self.customTask = [KKJSBridgeConfig.ajaxDelegateManager dataTaskWithRequest:mutableReqeust callbackDelegate:self];
        } else {
            NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
            self.customTask = [session dataTaskWithRequest:mutableReqeust];
        }
        
        [self.customTask resume];
    } else {
        [self.client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"KKJSBridge" code:-999 userInfo:@{@"error": @"can not find cached body request"}]];
    }
}

- (void)stopLoading {
    if (self.customTask != nil) {
        [self.customTask  cancel];
    }
    
    // 清除缓存
    [KKJSBridgeXMLBodyCacheRequest deleteRequestBody:self.requestId];
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    // 清除缓存
    [KKJSBridgeXMLBodyCacheRequest deleteRequestBody:self.requestId];
    
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
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
}

- (void)JSBridgeAjax:(id<KKJSBridgeAjaxDelegate>)ajax didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)JSBridgeAjax:(id<KKJSBridgeAjaxDelegate>)ajax didCompleteWithError:(NSError * _Nullable)error {
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
    
    // 清除缓存
    [KKJSBridgeXMLBodyCacheRequest deleteRequestBody:self.requestId];
}

#pragma mark - util
/**
 
 type BodyType = "String" | "Blob" | "FormData" | "ArrayBuffer";
 
 {
    //请求唯一id
    requestId,
    //当前 href url
    requestHref,
    //请求 Url
    requestUrl,
    //body 类型
    bodyType
    //body 具体值
    value
}
*/
- (void)setBodyRequest:(NSDictionary *)bodyRequest toRequest:(NSMutableURLRequest *)request {
    NSData *data = nil;
    NSString *bodyType = bodyRequest[@"bodyType"];
    id value = bodyRequest[@"value"];
    if (!value) {
        return;
    }
    
    if ([bodyType isEqualToString:@"Blob"]) {
        data = [self dataFromBase64:value];
    } else if ([bodyType isEqualToString:@"ArrayBuffer"]) {
        data = [self dataFromBase64:value];
    } else if ([bodyType isEqualToString:@"FormData"]) {
        [self setFormData:value toRequest:request];
        return;
    } else {//String
        if ([value isKindOfClass:NSDictionary.class]) {
            // application/json
            data = [NSJSONSerialization dataWithJSONObject:value options:0 error:nil];
        } else if ([value isKindOfClass:NSString.class]) {
            // application/x-www-form-urlencoded
            // name1=value1&name2=value2
            data = [value dataUsingEncoding:NSUTF8StringEncoding];
        } else {
            data = value;
        }
    }
    
    request.HTTPBody = data;
}

- (NSData *)dataFromBase64:(NSString *)base64 {
    // data:image/png;base64,iVBORw0...
    NSArray<NSString *> *components = [base64 componentsSeparatedByString:@","];
    if (components.count != 2) {
        return nil;
    }
    
    NSString *splitBase64 = components.lastObject;
    NSUInteger paddedLength = splitBase64.length + (splitBase64.length % 4);
    NSString *fixBase64 = [splitBase64 stringByPaddingToLength:paddedLength withString:@"=" startingAtIndex:0];
    NSData *data = [[NSData alloc] initWithBase64EncodedString:fixBase64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    return data;
}

- (void)setFormData:(NSDictionary *)formDataJson toRequest:(NSMutableURLRequest *)request {
    NSArray<NSString *> *fileKeys = formDataJson[@"fileKeys"];
    NSArray<NSArray *> *formData = formDataJson[@"formData"];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSMutableArray<KKJSBridgeFormDataFile *> *fileDatas = [NSMutableArray array];
    
    for (NSArray *pair in formData) {
        if (pair.count < 2) {
            continue;
        }
        
        NSString *key = pair[0];
        if ([fileKeys containsObject:key]) {// 说明存储的是个文件数据
            NSDictionary *fileJson = pair[1];
            KKJSBridgeFormDataFile *fileData = [KKJSBridgeFormDataFile new];
            fileData.key = key;
            fileData.size = [fileJson[@"size"] unsignedIntegerValue];
            fileData.type = fileJson[@"type"];
            
            if (fileJson[@"name"] && [fileJson[@"name"] length] > 0) {
                fileData.fileName = fileJson[@"name"];
            } else {
                fileData.fileName = fileData.key;
            }
            if (fileJson[@"lastModified"] && [fileJson[@"lastModified"] unsignedIntegerValue] > 0) {
                fileData.lastModified = [fileJson[@"lastModified"] unsignedIntegerValue];
            }
            if ([fileJson[@"data"] isKindOfClass:NSString.class]) {
                NSString *base64 = (NSString *)fileJson[@"data"];
                NSData *byteData = [self dataFromBase64:base64];
                fileData.data = byteData;
            }
            
            [fileDatas addObject:fileData];
        } else {
            params[key] = pair[1];
        }
    }
    
    KKJSBridgeURLRequestSerialization *serializer = [KKJSBridgeAjaxURLProtocol urlRequestSerialization];
    [serializer multipartFormRequestWithRequest:request parameters:params constructingBodyWithBlock:^(id<KKJSBridgeMultipartFormData>  _Nonnull formData) {
        for (KKJSBridgeFormDataFile *fileData in fileDatas) {
            [formData appendPartWithFileData:fileData.data name:fileData.key fileName:fileData.fileName mimeType:fileData.type];
        }
    } error:nil];
}

- (NSDictionary *)queryParams:(NSString *)absoluteString {
    NSMutableDictionary *pairs = [NSMutableDictionary dictionary];
    if (NSNotFound != [absoluteString rangeOfString:@"?"].location) {
        NSString *paramString = [absoluteString substringFromIndex:
                                 ([absoluteString rangeOfString:@"?"].location + 1)];
        NSCharacterSet *delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@"&"];
        NSScanner *scanner = [[NSScanner alloc] initWithString:paramString];
        while (![scanner isAtEnd]) {
            NSString* pairString = nil;
            [scanner scanUpToCharactersFromSet:delimiterSet intoString:&pairString];
            [scanner scanCharactersFromSet:delimiterSet intoString:NULL];
            NSArray *kvPair = [pairString componentsSeparatedByString:@"="];
            if (kvPair.count == 2) {
                NSString *key = [[kvPair objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                NSString *value = [[kvPair objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                [pairs setValue:value forKey:key];
            }
        }
    }
    
    return [NSDictionary dictionaryWithDictionary:pairs];
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
