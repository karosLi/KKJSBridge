/*
 * @Author: your name
 * @Date: 2020-06-20 11:29:12
 * @LastEditTime: 2020-11-20 23:35:57
 * @LastEditors: Please set LastEditors
 * @Description: In User Settings Edit
 * @FilePath: /TS/src/indexnew.ts
 */ 
/// <reference path="./index.d.ts" />
import * as FetchHook from "./lib/fetch.js"

var init = function() {
    if (window.KKJSBridge) {
      return;
    }

    /**
     * 处理 iframe 相关
     */
    class KKJSBridgeIframe {
      /**
       * 分发消息
       * @param messageString
       */
      public static dispatchMessage(messageString: string) {
        // 处理有 iframe 的情况
        let iframes : NodeListOf<HTMLIFrameElement> = document.querySelectorAll("iframe");
        if (iframes) {
          let len: number = iframes.length;
          for (let i = 0; i < len; i++) {
            let win: any = iframes[i].contentWindow;
            win.postMessage(messageString, '*');
          }
        }
      }

      /**
       * 添加消息监听处理
       */
      public static addMessageListener() {
        // iframe 内处理来自父 window 的消息
        window.addEventListener('message', e => {
          let data: any = e.data;
          if (typeof data == "string") {
            let str: string = data as string;
            if (str.indexOf("messageType") != -1) {
              KKJSBridgeInstance._handleMessageFromNative(str);
            }
          }
        });
      }

      /**
       * 让 iframe 能够注入 app 里面的脚本
       */
      public static hookSandbox() {
        // 设置 iframe 标签 的 sandbox 属性
        document.addEventListener('DOMContentLoaded',function(){
          let iframes : NodeListOf<HTMLIFrameElement> = document.querySelectorAll("iframe");
          if (iframes) {
            let len: number = iframes.length;
            for (let i = 0; i < len; i++) {
              let iframe: HTMLIFrameElement = iframes[i];
              if (iframe.getAttribute('sandbox') && iframe.getAttribute('sandbox').indexOf('allow-scripts') == -1) {
                iframe.setAttribute('sandbox', iframe.getAttribute('sandbox') + ' allow-scripts');
              }
            }
          }
        });

        // 设置 iframe 动态创建的 sandbox 属性
        let originalCreateElement = document.createElement;
        document.createElement = function (tag: string) {
          var element = originalCreateElement.call(document, tag);
          if (tag.toLowerCase() === 'iframe') {
            try {
              var iframeSandbox = Object.getOwnPropertyDescriptor(window.HTMLIFrameElement, 'sandbox') ||
                            Object.getOwnPropertyDescriptor(HTMLIFrameElement.prototype, 'sandbox');
              if (iframeSandbox && iframeSandbox.configurable) {
                  Object.defineProperty(element, 'sandbox', {
                    configurable: true,
                    enumerable: true,
                    get: function () {
                      return iframeSandbox.get.call(element);
                    },
                    set: function (val) {
                      if (val.indexOf('allow-scripts') == -1) {
                        val = val + ' allow-scripts';
                      }
                      iframeSandbox.set.call(element, val);
                    }
                  });
              }
            } catch(e) {
              console.log('this browser does not support reconfigure iframe sandbox property', e);
            }
          }
          return element;
        };
      }
    }
    
    /**
     * 建立与 native 的数据通信
     */
    class KKJSBridge {
      private uniqueId: number; // 用于记录标记唯一的函数回调
      private callbackCache: { [key: string]: KK.Callback }; // 用于 H5 监听来自 Native 的回调
      private eventCallbackCache: { [key: string]: [KK.EventCallback] }; // 用于处理来自 Native 的事件
  
      constructor() {
        this.uniqueId = 1;
        this.callbackCache = {};
        this.eventCallbackCache = {};
      }
  
      /**
       * 调用 Natvie 方法
       * @param module 模块
       * @param method 方法
       * @param data 数据
       * @param callback 调用回调
       */
      private callNative(module: string, method: string, data: {}, callback?: KK.Callback) {
        let message: KK.SendMessage = {
          module: module || 'default',
          method,
          data : data,
          callbackId: null
        };
  
        if (callback) {
          // 拼装 callbackId
          const callbackId: string =  'cb_' + message.module + '_' + method + '_' + (this.uniqueId++) + '_' + new Date().getTime();
          // 缓存 callback，用于在 Native 处理完消息后，通知 H5
          this.callbackCache[callbackId] = callback;
          // 追加 callbackId 属性
          message.callbackId = callbackId;
        }
  
        // 发送消息给 Native
        window.webkit.messageHandlers.KKJSBridgeMessage.postMessage(message);
      }
  
      /**
       * 用于处理来自 Native 的消息
       * @param callbackMessage 回调消息
       */
      public _handleMessageFromNative(messageString: string) {
        let callbackMessage: KK.CallbackMessage = JSON.parse(messageString);
        if (callbackMessage.messageType === KK.MessageType.Callback) { // 回调消息
          let callback: KK.Callback = this.callbackCache[callbackMessage.callbackId];
          if (callback) { // 执行 callback 回调，并删除缓存的 callback
            callback(callbackMessage.data);
            this.callbackCache[callbackMessage.callbackId] = null;
            delete this.callbackCache[callbackMessage.callbackId];
          }
        } else if (callbackMessage.messageType === KK.MessageType.Event) { // 事件消息
          // 支持批量事件调用
          let obsevers: [KK.EventCallback] = this.eventCallbackCache[callbackMessage.eventName];
          if (obsevers) {
            for(let i = 0; i < obsevers.length; i++) {
              let eventCallback: KK.EventCallback = obsevers[i];
              if (eventCallback) {
                eventCallback(callbackMessage.data);
              }
            }
          }
        }

        // 处理有 iframe 的情况
        KKJSBridgeIframe.dispatchMessage(messageString);
      }
  
      /**
       * 异步调用方法
       * @param module 模块
       * @param method 方法
       * @param data 数据
       * @param callback 调用回调
       */
      public call(module: string, method: string, data: {}, callback?: KK.Callback) {
        this.callNative(module, method, data, callback);
      }

      /**
       * 同步调用方法
       * @param module 模块
       * @param method 方法
       * @param data 数据
       */
      public syncCall(module: string, method: string, data: {}) : any {
        let message: KK.SendMessage = {
          module: module || 'default',
          method,
          data : data,
        };

        const messageString: string = JSON.stringify(message);
        let response: any = window.prompt("KKJSBridge", messageString);
        return response ? JSON.parse(response) : null;
      }
  
      /**
       * 监听事件
       * @param eventName 事件名字
       * @param callback 事件回调
       */
      public on(eventName: string, callback: KK.EventCallback) {
        // 使用数组，支持多个观察者
        let obsevers: [KK.EventCallback] = this.eventCallbackCache[eventName];
        if (obsevers) {
          obsevers.push(callback);
        } else {
          obsevers = [callback];
          this.eventCallbackCache[eventName] = obsevers;
        }
      }
  
      /**
       * 取消监听事件
       * @param eventName 事件名字
       */
      public off(eventName: string) {
        let obsevers: [KK.EventCallback] = this.eventCallbackCache[eventName];
        if (obsevers && obsevers.length > 0) {
          obsevers.splice(0, obsevers.length);
        }
      }
    }
  
    // 初始化 KKJSBridge
    let KKJSBridgeInstance = new KKJSBridge();

    // iframe 内处理来自父 window 的消息
    KKJSBridgeIframe.addMessageListener();
    // 设置 iframe 的 sandbox 属性
    KKJSBridgeIframe.hookSandbox();

    /**
     * KKJSBridge 工具
     */
    class KKJSBridgeUtil {
      
      /**
        把 arraybuffer 转成 base64
      */
      public static convertArrayBufferToBase64(arraybuffer: ArrayBuffer) {
        let uint8Array: Uint8Array = new Uint8Array(arraybuffer);
        let charCode: string = "";
        let length = uint8Array.byteLength;
        for (let i = 0; i < length; i++) {
          charCode += String.fromCharCode(uint8Array[i]);
        }
        // 字符串转成base64
        return window.btoa(charCode);
      }

      public static convertFormDataToJson(formData: any, callback: (json: any) => void) {
        let promise = new Promise<any>(async (resolve, reject) => {
          let formDataJson: any = {};
          let formDataFileKeys = [];
          let formDatas: any = [];
  
          if (formData._entries) { // 低版本的 iOS 系统，并不支持 entries() 方法，所以这里做兼容处理
            for(let i = 0; i < formData._entries.length; i++) {
              let pair = formData._entries[i];
              let key: string = pair[0];
              let value: any = pair[1];
              let fileName = pair.length > 2 ? pair[2] : null;
              let singleKeyValue = [];
              singleKeyValue.push(key);
  
              if (value instanceof File || value instanceof Blob) { // 针对文件特殊处理
                let formDataFile: KK.FormDataFile = await KKJSBridgeUtil.convertFileToJson(value);
                if (fileName) { // 文件名需要处理下
                  formDataFile.name = fileName;
                }
  
                singleKeyValue.push(formDataFile);
                formDataFileKeys.push(key);
              } else {
                singleKeyValue.push(value);
              }
  
              formDatas.push(singleKeyValue);
            }
          } else {
            // JS 里 FormData 表单实际上也是一个键值对
            for(let pair of formData.entries()) {
              let key: string = pair[0];
              let value: any = pair[1];
              let singleKeyValue = [];
              singleKeyValue.push(key);
  
              if (value instanceof File || value instanceof Blob) { // 针对文件特殊处理
                let formDataFile: KK.FormDataFile = await KKJSBridgeUtil.convertFileToJson(value);
                singleKeyValue.push(formDataFile);
                formDataFileKeys.push(key);
              } else {
                singleKeyValue.push(value);
              }
  
              formDatas.push(singleKeyValue);
            }
          }
          
          formDataJson['fileKeys'] = formDataFileKeys;
          formDataJson['formData'] = formDatas;
          resolve(formDataJson);
        });
  
        promise.then((json: any) => {
          callback(json);
        }).catch(function (error: Error) {
            console.log(error);
        });
      }
  
      /**
       * 读取单个文件数据，并转成 base64，最后返回 json 对象
       * @param file 
       */
      public static convertFileToJson(file: File | Blob) {
        return new Promise<any>((resolve, reject) => {
          let reader: FileReader = new FileReader();
          reader.readAsDataURL(file);
          reader.onload = function(this: FileReader, ev: ProgressEvent) {
              let base64: string = (ev.target as any).result;
              let formDataFile: KK.FormDataFile = {
                name: file instanceof File ? (file as File).name : '',
                lastModified: file instanceof File ? (file as File).lastModified : 0,
                size: file.size,
                type: file.type,
                data: base64
              };
              resolve(formDataFile);
              return null;
          };
          reader.onerror = function(this: FileReader, ev: ProgressEvent) {
            reject(Error("formdata 表单读取文件数据失败"));
            return null;
          };
        });
      }
    }
  
    /**
     * Hook FormData，由于低版本的 FormData 没有支持 entries() 等遍历 api，所以只是在 ajax send 里遍历，是无法获取到具体的值的，
     * 所以针对低版本的 iOS 系统做 Hook FormData 处理。
     */
    var originAppend = window.FormData.prototype['append'];
    var originEntries = window.FormData.prototype['entries'];
    if (!originEntries) {
      window.FormData.prototype['append'] = function() {
        if (!this._entries) {
          this._entries = [];
        }
        this._entries.push(arguments);
        return originAppend.apply(this, arguments);
      }
    }

    /**
     * hook document.cookie
     */
    class _COOKIE {
      // 静态属性和方法
      public static readonly moduleName: string = 'cookie';
      /**
       * 通过重新定义 cookie 属性来进行 cookie hook
       */
      public static hookCookie: Function = () => {
        try {
          var cookieDesc = Object.getOwnPropertyDescriptor(Document.prototype, 'cookie') ||
                       Object.getOwnPropertyDescriptor(HTMLDocument.prototype, 'cookie');
          if (cookieDesc && cookieDesc.configurable) {
              Object.defineProperty(document, 'cookie', {
                configurable: true,
                enumerable: true,
                get: function () {
                  // console.log('getCookie');
                  if (KKJSBridgeConfig.cookieHook) {// 如果开启 cookie hook，则从 Native 读取 cookie
                    let cookieJson: any = window.KKJSBridge.syncCall(_COOKIE.moduleName, 'cookie', {
                      "url" : window.location.href
                    });
                    return cookieJson.cookie;
                  }

                  return cookieDesc.get.call(document);
                },
                set: function (val) {
                  // console.log('setCookie');
                  if (KKJSBridgeConfig.cookieHook) {// 如果开启 cookie hook，则需要把 cookie 同步给 Native
                    window.KKJSBridge.call(_COOKIE.moduleName, 'setCookie', {
                      "cookie" : val
                    });
                  }

                  cookieDesc.set.call(document, val);
                }
              });
          }
        } catch(e) {
          console.log('this browser does not support reconfigure document.cookie property', e);
        }
      };
    }
  
    window._COOKIE = _COOKIE;
    window._COOKIE.hookCookie();
    
    /**
     * AJAX 相关方法
     */
    class _XHR {
      // 静态属性和方法
      public static readonly moduleName: string = 'ajax';
      public static globalId: number = Math.floor(Math.random() * 100000);
      public static callbackCache: any[] = [];
  
      /**
       * 生成 ajax 请求唯一id
       */
      public static generateXHRRequestId: Function = () => {
        return (new Date).getTime() + "" + _XHR.globalId++; // 时间戳 + 当前上下文唯一id，生成请求id
      }

      /**
       * 给表单生成新的 action
       */
      public static generateNewActionForForm: Function = (form: HTMLFormElement, requestId: string) => {
        let orignAction: string = form.action;
        form.action = _XHR.generateNewUrlWithRequestId(orignAction, requestId);
      }

      /**
       * 利用 requestId 生成新的 url
       */
      public static generateNewUrlWithRequestId: Function = (url: string, requestId: string) => {
        let orignAction: string = url;

        // 通过 a 标签来辅助拼接新的 action
        let aTag: HTMLAnchorElement = document.createElement("a");
        aTag.href = orignAction;
        let search: string = aTag.search ? aTag.search : "";
        let hash: string = aTag.hash ? aTag.hash : "";

        if (/KKJSBridge-RequestId/.test(orignAction)) {// 防止重复追加 requestId
          aTag.search = aTag.search.replace(/KKJSBridge-RequestId=(\d+)/, "KKJSBridge-RequestId=" + requestId);
        } else if (aTag.search && aTag.search.length > 0) {
          let s: string = aTag.search;
          if (/KKJSBridge-RequestId/.test(s)) {// 防止重复追加 requestId
            aTag.search = s.replace(/KKJSBridge-RequestId=(\d+)/, "KKJSBridge-RequestId=" + requestId);
          } else {
            aTag.search = s + "&KKJSBridge-RequestId=" + requestId;
          }
        } else {
          aTag.search = "?KKJSBridge-RequestId=" + requestId;
        }

        url = orignAction.replace(search, "").replace(hash, "");
        if ("#" === url.trim()) {
          url = "";
        }

        let newAction: string = url + aTag.search + aTag.hash;
        return newAction;
      }

      /**
       * 给 open url 生成带请求 id 的新 url
       */
      public static generateNewOpenUrlWithRequestId: Function = (url: string, requestId: string) => {
        let getOpenUrlReuestId: Function = function(requestId: string) {
          return "^^^^" + requestId + "^^^^"
        }
        let openUrlReuestReg: any = /\^\^\^\^(\d+)\^\^\^\^/;
        // 通过 a 标签来辅助拼接新的 action
        let aTag: HTMLAnchorElement = document.createElement("a");
        aTag.href = url;
        let hash: string = aTag.hash ? aTag.hash : "";
        
        if (openUrlReuestReg.test(aTag.hash)) {
          aTag.hash = aTag.hash.replace(openUrlReuestReg, getOpenUrlReuestId(requestId));
        } else if (aTag.hash && aTag.hash.length > 0) {
          aTag.hash = aTag.hash + getOpenUrlReuestId(requestId);
        } else {
          aTag.hash = getOpenUrlReuestId(requestId);
        }

        url = url.replace(hash, "");
        if ("#" === url.trim()) {
          url = "";
        }

        let newUrl: string = url + aTag.hash;
        return newUrl;
      }

      /**
       * 发送 body 到 native 侧缓存起来
       * @param xhr 
       * @param originMethod 
       * @param originArguments 
       * @param body 
       */
      public static sendBodyToNativeForCache: Function = (targetType: "AJAX" | "FORM", target: XMLHttpRequest | HTMLFormElement, 
        originMethod: any, 
        originArguments: any, 
        request: KK.AJAXBodyCacheRequest,
        requestAsync: boolean = true) => {
        
        let requestId: string = target.requestId;
        let cacheCallback: KK.AJAXBodyCacheCallback = {
          requestId: requestId,
          callback: ()=> {
            // if (targetType === "AJAX") {// ajax
            //   // 发送之前设置自定义请求头，好让 native 拦截并从缓存里获取 body
            //   target.setRequestHeader("KKJSBridge-RequestId", requestId);
            // }
            
            if (targetType === "FORM") {// 表单 submit
              // 发送之前修改 action，让 action 带上 requestId
              _XHR.generateNewActionForForm(target, requestId);
            }
            
            // 调用原始 send 方法 
            return originMethod.apply(target, originArguments);
          }
        };

        if (requestAsync) {// 异步请求
          // 缓存 callbcak
          _XHR.callbackCache[requestId] = cacheCallback;
          // 发送 body 请求到 native
          window.KKJSBridge.call(_XHR.moduleName, 'cacheAJAXBody', request, (message: any) => {
            // 处理 native 侧缓存完毕后的消息
            let callbackFromNative: KK.AJAXBodyCacheCallback = message;
            let requestId: string = callbackFromNative.requestId;
            // 通过请求 id，找到原始 send 方法并调用
            if (_XHR.callbackCache[requestId]) {
              let callbackFromNative: KK.AJAXBodyCacheCallback = _XHR.callbackCache[requestId];
              if (callbackFromNative.callback) {
                callbackFromNative.callback();
              }
              delete _XHR.callbackCache[requestId];
            }
          });
          return;
        }

        // 同步请求
        // 发送 body 请求到 native
        window.KKJSBridge.syncCall(_XHR.moduleName, 'cacheAJAXBody', request);
        // 发送完成后继续请求原始 send 方法
        cacheCallback.callback();
      }
    }
    window._XHR = _XHR;

    /**
     * 只 hook open/send 方法
     */
    let originOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function(method: string, url: string, async: boolean, username?: string | null, password?: string | null) {
      let args: any = [].slice.call(arguments);
      let xhr: XMLHttpRequest = this;
      // 生成唯一请求id
      xhr.requestId = _XHR.generateXHRRequestId();
      xhr.requestUrl = url;
      xhr.requestHref = document.location.href;
      xhr.requestMethod = method;
      xhr.requestAsync = async;

      if (!KKJSBridgeConfig.ajaxHook) {// 如果没有开启 ajax hook，则调用原始 open
        return originOpen.apply(xhr, args);
      }
      
      // 生成新的 url
      args[1] = _XHR.generateNewUrlWithRequestId(url, xhr.requestId);
      originOpen.apply(xhr, args);
    } as any;

    let originSend = XMLHttpRequest.prototype.send;
    XMLHttpRequest.prototype.send = function(body?: string | Document | Blob | ArrayBufferView | ArrayBuffer | FormData | URLSearchParams | ReadableStream<Uint8Array>) {
      let args: any = [].slice.call(arguments);
      let xhr: XMLHttpRequest = this;
      let request: KK.AJAXBodyCacheRequest = {
        requestId: xhr.requestId,
        requestHref: xhr.requestHref,
        requestUrl: xhr.requestUrl,
        bodyType: "String",
        value: null
      };
      
      if (!KKJSBridgeConfig.ajaxHook) {// 如果没有开启 ajax hook，则调用原始 send
        return originSend.apply(xhr, args);
      }

      if (!body) {// 没有 body，调用原始 send
        return originSend.apply(xhr, args);
      } else if (body instanceof ArrayBuffer) {// 说明是 ArrayBuffer，转成 base64
        request.bodyType = "ArrayBuffer";
        request.value = KKJSBridgeUtil.convertArrayBufferToBase64(body);
      } else if (body instanceof Blob) {// 说明是 Blob，转成 base64
        request.bodyType = "Blob";
        let fileReader: FileReader = new FileReader();
        fileReader.onload = function(this: FileReader, ev: ProgressEvent) {
          let base64: string = (ev.target as any).result;
          request.value = base64;
          _XHR.sendBodyToNativeForCache("AJAX", xhr, originSend, args, request, xhr.requestAsync);
        };

        fileReader.readAsDataURL(body);
        return;
      } else if (body instanceof FormData) {// 说明是表单
        request.bodyType = "FormData";
        request.formEnctype = "multipart/form-data";
        KKJSBridgeUtil.convertFormDataToJson(body, (json: any) => {
          request.value = json; 
          _XHR.sendBodyToNativeForCache("AJAX", xhr, originSend, args, request, xhr.requestAsync);
        });
        return;
      } else {// 说明是字符串或者json
        request.bodyType = "String";
        request.value = body;
      } 
      
      // 发送到 native 缓存起来
      _XHR.sendBodyToNativeForCache("AJAX", xhr, originSend, args, request, xhr.requestAsync);
    } as any;

    /**
     * hook form submit 方法
     */
    let originSubmit = HTMLFormElement.prototype.submit;
    HTMLFormElement.prototype.submit = function() {
      let args: any = [].slice.call(arguments);
      let form: HTMLFormElement = this;
      form.requestId = _XHR.generateXHRRequestId();
      form.requestUrl = form.action;
      form.requestHref = document.location.href;

      let request: KK.AJAXBodyCacheRequest = {
        requestId: form.requestId,
        requestHref: form.requestHref,
        requestUrl: form.requestUrl,
        bodyType: "FormData",
        formEnctype: form.enctype,
        value: null
      };

      if (!KKJSBridgeConfig.ajaxHook) {// 如果没有开启 ajax hook，则调用原始 submit
        return originSubmit.apply(form, args);
      }

      let action: string = form.action;
      if (!action) {// 如果 action 本身是空，则调用原始 submit
        return originSubmit.apply(form, args);
      }

      let formData: any = new FormData(form);
      KKJSBridgeUtil.convertFormDataToJson(formData, (json: any) => {
        request.value = json;
        _XHR.sendBodyToNativeForCache("FORM", form, originSubmit, args, request);
      });
    };
  
    /**
     * KKJSBridge 配置
     */
    class KKJSBridgeConfig {
      public static ajaxHook: boolean = false;
      public static cookieHook: boolean = true;
      
      public static init: Function = () => {
        window.KKJSBridge = KKJSBridgeInstance; // 设置新的 JSBridge 作为全局对象
      };
  
      /**
       * 开启 ajax hook
       */
      public static enableAjaxHook: Function = (enable: boolean) => {
        if (enable) {
          KKJSBridgeConfig.ajaxHook = true;
          FetchHook.enableFetchHook(true);
        } else {
          FetchHook.enableFetchHook(false);
          KKJSBridgeConfig.ajaxHook = false;
        }
      };

      /**
       * 开启 cookie hook
       */
      public static enableCookieHook: Function = (enable: boolean) => {
        if (enable) {
          KKJSBridgeConfig.cookieHook = true;
        } else {
          KKJSBridgeConfig.cookieHook = false;
        }
      };
  
      /**
       * bridge Ready
       */
      public static bridgeReady: Function = () => {
        window.KKJSBridge.call(_COOKIE.moduleName, 'bridgeReady', {});

        // 告诉 H5 新的 KKJSBridge 已经 ready
        let KKJSBridgeReadyEvent: Event = document.createEvent("Events");
        KKJSBridgeReadyEvent.initEvent("KKJSBridgeReady");
        document.dispatchEvent(KKJSBridgeReadyEvent);
      };
    }
  
    window.KKJSBridgeConfig = KKJSBridgeConfig;
    window.KKJSBridgeConfig.init(); // JSBridge 配置初始化
    window.KKJSBridgeConfig.bridgeReady();
};
init();
export default window.KKJSBridge;