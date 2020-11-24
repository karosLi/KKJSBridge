/// <reference path="../../types/index.d.ts" />
import * as FetchHook from "../lib/fetch.js"
import { KKJSBridgeUtil, KKJSBridgeIframe } from "../util/KKJSBridgeUtil"

/**
 * AJAX 相关方法
 */
export class _KKJSBridgeXHR {
	// 静态属性和方法
	public static readonly moduleName: string = 'ajax';
	public static globalId: number = Math.floor(Math.random() * 1000);
	public static cache: any[] = [];

	/**
	 * 用于处理来自 native 的异步回调
	 */
	public static setProperties: Function = (response: any) => {
		let jsonObj: any;

		if (typeof response == "string") {
			jsonObj = JSON.parse(response);
		} else {
			jsonObj = response;
		}

		let id: any = jsonObj.id;
		let xhr: any = _KKJSBridgeXHR.cache[id];
		if (xhr) {
			if (jsonObj.readyState === xhr.DONE) {
				// 防止重复利用 xhr 对象发送请求而导致 id 不变的问题
				xhr.isCached = false;
			}
			// 保存回调对象，对象子属性的处理放在了 hook 里。因为 xhr 代理对象的可读属性（readyState,status,statusText,responseText）都是从实际 xhr 拷贝过来的，相应的我们也是不能直接对这些可读属性赋值的
			xhr.callbackProperties = jsonObj;
			if (xhr.onreadystatechange) {
				xhr.onreadystatechange();
			}

			// 因为不能直接赋值给 xhr 的可读属性，所以这里是使用回调对象的属性来判断
			if (xhr.callbackProperties.readyState === xhr.LOADING && xhr.onprogress) {
				xhr.onprogress();
			}

			if (xhr.callbackProperties.readyState === xhr.DONE) {
				if (xhr.onload) {
					xhr.onload();
				}
			
				var load = document.createEvent("Events");
				load.initEvent("load");
				xhr.dispatchEvent(load);
			}
		}

		// 处理有 iframe 的情况
		KKJSBridgeIframe.dispatchMessage(response);
	};

	/**
	 * 删除已经已经处理过的请求
	 */
	public static deleteObject: Function = (id: any) => {
		if (_KKJSBridgeXHR.cache[id]) {
			delete _KKJSBridgeXHR.cache[id];
		}
	}

	/**
	 * 缓存 ajax 代理对象
	 */
	private static cacheXHRIfNeed: Function = (xhr: any) => {
		// 添加属性，并缓存 xhr
		if (!xhr.hasOwnProperty('id')) {
			Object.defineProperties(xhr, {
				'id': {
					value: 0,
					writable: true,
					enumerable: true
				},
				'callbackProperties': {
					value: {},
					writable: true,
					enumerable: true
				},
				'isCached': {
					value: false,
					writable: true,
					enumerable: true
				}
			});
			// readyState,status,statusText,responseText,headers
			Object.defineProperties(xhr.callbackProperties, {
				'readyState': {
					value: 0,
					writable: true,
					enumerable: true
				},
				'status': {
					value: 0,
					writable: true,
					enumerable: true
				},
				'statusText': {
					value: '',
					writable: true,
					enumerable: true
				},
				'responseText': {
					value: '',
					writable: true,
					enumerable: true
				},
				'headers': {
					value: {},
					writable: true,
					enumerable: true
				},
			});
		}

		if (!xhr.isCached) { // 避免重复缓存
			xhr.id = _KKJSBridgeXHR.globalId++; // 请求 id 计数加 1
			_KKJSBridgeXHR.cache[xhr.id] = xhr;
			xhr.isCached = true;
		}
	}

	/**
	 * 安装 AJAX Proxy
	 * https://github.com/wendux/Ajax-hook/blob/master/src/ajaxhook.js
	 */
	public static setupHook: Function = () => {
		let ob: any = {};
		//Save original XMLHttpRequest as RealXMLHttpRequest
		var realXhr = "RealXMLHttpRequest"
		//Call this function will override the `XMLHttpRequest` object
		ob.hookAjax = function (proxy: any) {
			// Avoid double hook
			window[realXhr] = window[realXhr] || XMLHttpRequest
			window.XMLHttpRequest = function () {
				var xhr = new window[realXhr];
				// We shouldn't hook XMLHttpRequest.prototype because we can't
				// guarantee that all attributes are on the prototype。
				// Instead, hooking XMLHttpRequest instance can avoid this problem.
				for (var attr in xhr) {
					var type = "";
					try {
						type = typeof xhr[attr]; // May cause exception on some browser
					} catch (e) {
						
					}
					if (type === "function") {
						// hook methods of xhr, such as `open`、`send` ...
						this[attr] = hookFunction(attr);
					} else {
						Object.defineProperty(this, attr, {
							get: getterFactory(attr),
							set: setterFactory(attr),
							enumerable: true
						});
					}
				}
				this.xhr = xhr;
			}
			// Generate getter for attributes of xhr
			function getterFactory(attr: string) {
				return function () {
					var v = this.hasOwnProperty(attr + "_") ? this[attr + "_"] : this.xhr[attr];
					var attrGetterHook = (proxy[attr] || {})["getter"];
					return attrGetterHook && attrGetterHook(v, this) || v;
				}
			}
			// Generate setter for attributes of xhr; by this we have an opportunity
			// to hook event callbacks （eg: `onload`） of xhr;
			function setterFactory(attr: string) {
				return function (v: any) {
					var xhr = this.xhr;
					var that = this;
					var hook = proxy[attr];
					if (typeof hook === "function") {
						// hook  event callbacks such as `onload`、`onreadystatechange`...
						xhr[attr] = function () {
							proxy[attr](that) || v.apply(xhr, arguments);
						}
					} else {
						//If the attribute isn't writable, generate proxy attribute
						var attrSetterHook = (hook || {})["setter"];
						v = attrSetterHook && attrSetterHook(v, that) || v;
						try {
							xhr[attr] = v;
						} catch (e) {
							this[attr + "_"] = v;
						}
					}
				}
			}
			// Hook methods of xhr.
			function hookFunction(fun: string) {
				return function () {
					var args = [].slice.call(arguments)
					/**
					if (proxy[fun] && proxy[fun].call(this, args, this.xhr)) {
							return;
					}

					需求上是需要在方法代理时，也把代理的值返回出去，所以这里修改了源码。
						*/
					if (proxy[fun]) {
						return proxy[fun].call(this, args, this.xhr);
					}
					return this.xhr[fun].apply(this.xhr, args);
				}
			}
			// Return the real XMLHttpRequest
			return window[realXhr];
		}
		// Cancel hook
		ob.unHookAjax = function () {
			if (window[realXhr]) XMLHttpRequest = window[realXhr];
			window[realXhr] = undefined;
		}
		window._KKJSBridgeAjaxProxy = ob;
	}

	/**
	 * 是否开启 ajax hook
	 */
	public static enableAjaxHook: Function = (enable: boolean) => {
		if (!enable) {
			window._KKJSBridgeAjaxProxy.unHookAjax();
			return;
		}

		/**
		 * https://developer.mozilla.org/zh-CN/docs/Web/API/XMLHttpRequest
		 * 
		 * 1、hook 之后，每个 XMLHttpRequest 代理对象里面都会对应一个真正的 XMLHttpRequest 对象。
		 * 2、支持基本属性 hook，事件属性回调 hook 和函数 hook。
		 * 3、基本属性和事件属性 hook 里的入参 xhr 参数是一个 XMLHttpRequest 代理对象。而函数 hook 里的入参 xhr 是一个实际 XMLHttpRequest。 所以可以给代理对象添加属性，然后在其他 hook 方法里共享属性。
		 * 4、函数 hook 返回 true 时，将会阻断真正的 XMLHttpRequest 的实际函数请求。
		 * 
		 **/ 
		window._KKJSBridgeAjaxProxy.hookAjax({
			// 拦截属性
			readyState: {
				getter: function(v: any, xhr: any) {
					if (xhr.callbackProperties) {
						return xhr.callbackProperties.readyState;
					}

					return false;
				}
			},
			status: {
				getter: function(v: any, xhr: any) {
					if (xhr.callbackProperties) {
						return xhr.callbackProperties.status;
					}
					
					return false;
				}
			},
			statusText: {
				getter: function(v: any, xhr: any) {
					if (xhr.callbackProperties) {
						return xhr.callbackProperties.statusText;
					}
					
					return false;
				}
			},
			responseText: {
				getter: function(v: any, xhr: any) {
					if (xhr.callbackProperties) {
						return xhr.callbackProperties.responseText;
					}
					
					return false;
				}
			},
			response: {
				getter: function(v: any, xhr: any) {
					if (xhr.callbackProperties) {
						return xhr.callbackProperties.responseText;
					}
					
					return false;
				}
			},
			//拦截回调
			onreadystatechange: function(xhr: any) {
				// nothing
			},
			onload: function(xhr: any) {
				// nothing
			},
			//拦截方法
			open: function(arg: any[], xhr: any) {
				console.log("open called: method:%s,url:%s,async:%s",arg[0],arg[1],arg[2]);
				const method: string = arg[0];
				const url: string = arg[1];
				const async: boolean = arg[2];
				this.requestAsync = async;
				_KKJSBridgeXHR.cacheXHRIfNeed(this);
				window.KKJSBridge.call(_KKJSBridgeXHR.moduleName, 'open', {
					"id" : this.id,
					"method" : method,
					"url" : url,
					"scheme" : window.location.protocol,
					"host" : window.location.hostname,
					"port" : window.location.port,
					"href" : window.location.href,
					"referer" : document.referrer != "" ? document.referrer : null,
					"useragent" : navigator.userAgent,
					"async" : async,
					// "timeout" : this.timeout
				});

				return true;
			},
			send: function(arg: any[], xhr: any) {
				console.log("send called:", arg[0]);
				let body: any = arg[0];
				let requestAsync: boolean = this.requestAsync;
				let bodyRequest: KK.AJAXBodySendRequest = {
					id: this.id,
					bodyType: "String",
					value: null
				};

				function sendBody(bodyRequest: KK.AJAXBodySendRequest, requestAsync: boolean = true) {
					/* 
						ajax 同步请求只支持纯文本数据，不支持 Blob 和 FormData 数据。
						如果要支持的话，必须使用 FileReaderSync 对象，但是该对象只在 workers 里可用，
						因为在主线程里进行同步 I/O 操作可能会阻塞用户界面。
						https://developer.mozilla.org/zh-CN/docs/Web/API/FileReaderSync
					*/

					if (requestAsync) {// 异步 send 请求
						window.KKJSBridge.call(_KKJSBridgeXHR.moduleName, 'send', bodyRequest);
						return;
					}

					// 同步 send 请求
					let response: any = window.KKJSBridge.syncCall(_KKJSBridgeXHR.moduleName, 'send', bodyRequest);
					// 处理请求回来的结果
					_KKJSBridgeXHR.setProperties(response);
				}

				if (body instanceof ArrayBuffer) {// 说明是 ArrayBuffer，转成 base64
					bodyRequest.bodyType = "ArrayBuffer";
					bodyRequest.value = KKJSBridgeUtil.convertArrayBufferToBase64(body);
				} else if (body instanceof Blob) {// 说明是 Blob，转成 base64
					bodyRequest.bodyType = "Blob";
					let fileReader: FileReader = new FileReader();
					fileReader.onload = function(this: FileReader, ev: ProgressEvent) {
						let base64: string = (ev.target as any).result;
						bodyRequest.value = base64;
						sendBody(bodyRequest);
					};
	
					fileReader.readAsDataURL(body);
					return true;
				} else if (body instanceof FormData) {// 说明是表单
					bodyRequest.bodyType = "FormData";
					bodyRequest.formEnctype = "multipart/form-data";
					KKJSBridgeUtil.convertFormDataToJson(body, (json: any) => {
						bodyRequest.value = json; 
						sendBody(bodyRequest);
					});
					return true;
				} else {// 说明是字符串或者json
					bodyRequest.bodyType = "String";
					bodyRequest.value = body;
				} 
				
				sendBody(bodyRequest, requestAsync);
				return true;
			},
			overrideMimeType: function(arg: any[], xhr: any) {
				// console.log("overrideMimeType called:", arg[0]);
				_KKJSBridgeXHR.cacheXHRIfNeed(this);
				let mimetype : string = arg[0];
				window.KKJSBridge.call(_KKJSBridgeXHR.moduleName, 'overrideMimeType', {
					"id" : this.id,
					"mimetype" : mimetype
				});

				return true;
			},
			abort: function(arg: any[], xhr: any) {
				console.log("abort called");
				window.KKJSBridge.call(_KKJSBridgeXHR.moduleName, 'abort', {
					"id" : this.id
				});

				return true;
			},
			setRequestHeader: function(arg: any[], xhr: any) {
				// console.log("setRequestHeader called:", arg[0], arg[1]);
				let headerName : string = arg[0];
				let headerValue : string = arg[1];
				window.KKJSBridge.call(_KKJSBridgeXHR.moduleName, 'setRequestHeader', {
					"id" : this.id,
					"headerName" : headerName,
					"headerValue" : headerValue
				});

				return true;
			},
			getAllResponseHeaders: function(arg: any[], xhr: any) {
				// console.log("getAllResponseHeaders called");
				let strHeaders: string = '';
				for (let name in this.callbackProperties.headers) {
					strHeaders += (name + ": " + this.callbackProperties.headers[name] + "\r\n");
				}
				return strHeaders;
			},
			getResponseHeader: function(arg: any[], xhr: any) {
				console.log("getResponseHeader called:", arg[0]);
				let headerName: string = arg[0];
				let strHeaders: string = '';
				let upperCaseHeaderName: string = headerName.toUpperCase();
				for (let name in this.callbackProperties.headers) {
					if (upperCaseHeaderName == name.toUpperCase())
						strHeaders = this.callbackProperties.headers[name]
				}
				return strHeaders;
			},
		});
	}

	/**
	 * 是否开启 fetch hook
	 */
	public static enableFetchHook: Function = (enable: boolean) => {
		FetchHook.enableFetchHook(enable);
	}
}
	
