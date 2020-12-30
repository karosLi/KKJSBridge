/// <reference path="../../types/index.d.ts" />
import { KKJSBridgeUtil } from "../util/KKJSBridgeUtil"

/**
 * AJAX 相关方法
 */
export class _KKJSBridgeXHR {
	// 静态属性和方法
	public static readonly moduleName: string = 'ajax';
	public static globalId: number = Math.floor(Math.random() * 100000);
	public static callbackCache: any[] = [];

	/**
	 * 生成 ajax 请求唯一id
	 */
	public static generateXHRRequestId: Function = () => {
		return (new Date).getTime() + "" + _KKJSBridgeXHR.globalId++; // 时间戳 + 当前上下文唯一id，生成请求id
	}

	/**
	 * 给表单生成新的 action
	 */
	public static generateNewActionForForm: Function = (form: HTMLFormElement, requestId: string) => {
		let orignAction: string = form.action;
		form.action = _KKJSBridgeXHR.generateNewUrlWithRequestId(orignAction, requestId);
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
	 * 是否是非正常的 http 请求。比如 url: blob:https:// 场景下，去发送 XMLHTTPRequest，会导致请求失败
	 */
	public static isNonNormalHttpRequest: Function = (url: string, httpMethod: string) => {
		let pattern: any = /^((http|https):\/\/)/;
		let isNonNormalRequest: Boolean = !pattern.test(url) && httpMethod === "GET";
		return isNonNormalRequest;
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

		/* 
			ajax 同步请求只支持纯文本数据，不支持 Blob 和 FormData 数据。
			如果要支持的话，必须使用 FileReaderSync 对象，但是该对象只在 workers 里可用，
			因为在主线程里进行同步 I/O 操作可能会阻塞用户界面。
			https://developer.mozilla.org/zh-CN/docs/Web/API/FileReaderSync
		*/
		
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
					_KKJSBridgeXHR.generateNewActionForForm(target, requestId);
				}
				
				// 调用原始 send 方法 
				return originMethod.apply(target, originArguments);
			}
		};

		if (requestAsync) {// 异步请求
			// 缓存 callbcak
			_KKJSBridgeXHR.callbackCache[requestId] = cacheCallback;
			// 发送 body 请求到 native
			window.KKJSBridge.call(_KKJSBridgeXHR.moduleName, 'cacheAJAXBody', request, (message: any) => {
				// 处理 native 侧缓存完毕后的消息
				let callbackFromNative: KK.AJAXBodyCacheCallback = message;
				let requestId: string = callbackFromNative.requestId;
				// 通过请求 id，找到原始 send 方法并调用
				if (_KKJSBridgeXHR.callbackCache[requestId]) {
					let callbackFromNative: KK.AJAXBodyCacheCallback = _KKJSBridgeXHR.callbackCache[requestId];
					if (callbackFromNative && callbackFromNative.callback && typeof callbackFromNative.callback == "function") {
						callbackFromNative.callback();
					}
					delete _KKJSBridgeXHR.callbackCache[requestId];
				}
			});
			return;
		}

		// 同步请求
		// 发送 body 请求到 native
		window.KKJSBridge.syncCall(_KKJSBridgeXHR.moduleName, 'cacheAJAXBody', request);
		// 发送完成后继续请求原始 send 方法
		cacheCallback.callback();
	}

	/**
	 * 安装 AJAX Proxy
	 */
	public static setupHook: Function = () => {
    /**
     * 只 hook open/send 方法
     */
    let originOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function(method: string, url: string, async: boolean, username?: string | null, password?: string | null) {
      let args: any = [].slice.call(arguments);
      let xhr: XMLHttpRequest = this;
      // 生成唯一请求id
      xhr.requestId = _KKJSBridgeXHR.generateXHRRequestId();
      xhr.requestUrl = url;
      xhr.requestHref = document.location.href;
      xhr.requestMethod = method;
			xhr.requestAsync = async;
			
			if (_KKJSBridgeXHR.isNonNormalHttpRequest(url, method)) {// 如果是非正常请求，则调用原始 open
				return originOpen.apply(xhr, args);
			}

      if (!window.KKJSBridgeConfig.ajaxHook) {// 如果没有开启 ajax hook，则调用原始 open
        return originOpen.apply(xhr, args);
      }
      
      // 生成新的 url
      args[1] = _KKJSBridgeXHR.generateNewUrlWithRequestId(url, xhr.requestId);
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
			
			if (_KKJSBridgeXHR.isNonNormalHttpRequest(xhr.requestUrl, xhr.requestMethod)) {// 如果是非正常请求，则调用原始 send
				return originSend.apply(xhr, args);
			}
      
      if (!window.KKJSBridgeConfig.ajaxHook) {// 如果没有开启 ajax hook，则调用原始 send
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
          _KKJSBridgeXHR.sendBodyToNativeForCache("AJAX", xhr, originSend, args, request);
        };

        fileReader.readAsDataURL(body);
        return;
      } else if (body instanceof FormData) {// 说明是表单
        request.bodyType = "FormData";
        request.formEnctype = "multipart/form-data";
        KKJSBridgeUtil.convertFormDataToJson(body, (json: any) => {
          request.value = json; 
          _KKJSBridgeXHR.sendBodyToNativeForCache("AJAX", xhr, originSend, args, request);
        });
        return;
      } else {// 说明是字符串或者json
        request.bodyType = "String";
        request.value = body;
      } 
      
      // 发送到 native 缓存起来
      _KKJSBridgeXHR.sendBodyToNativeForCache("AJAX", xhr, originSend, args, request, xhr.requestAsync);
    } as any;

    /**
     * hook form submit 方法
     */
    let originSubmit = HTMLFormElement.prototype.submit;
    HTMLFormElement.prototype.submit = function() {
      let args: any = [].slice.call(arguments);
      let form: HTMLFormElement = this;
      form.requestId = _KKJSBridgeXHR.generateXHRRequestId();
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

      if (!window.KKJSBridgeConfig.ajaxHook) {// 如果没有开启 ajax hook，则调用原始 submit
        return originSubmit.apply(form, args);
      }

      let action: string = form.action;
      if (!action) {// 如果 action 本身是空，则调用原始 submit
        return originSubmit.apply(form, args);
      }

      let formData: any = new FormData(form);
      KKJSBridgeUtil.convertFormDataToJson(formData, (json: any) => {
        request.value = json;
        _KKJSBridgeXHR.sendBodyToNativeForCache("FORM", form, originSubmit, args, request);
      });
    };
	}
}
