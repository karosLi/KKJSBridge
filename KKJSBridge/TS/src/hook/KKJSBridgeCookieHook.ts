/// <reference path="../../types/index.d.ts" />

/**
 * hook document.cookie
 */
export class _KKJSBridgeCOOKIE {
	// 静态属性和方法
	public static readonly moduleName: string = 'cookie';

	/**
	 * 通过重新定义 cookie 属性来进行 cookie hook
	 */
	public static setupHook: Function = () => {
		try {
			var cookieDesc = Object.getOwnPropertyDescriptor(Document.prototype, 'cookie') ||
										Object.getOwnPropertyDescriptor(HTMLDocument.prototype, 'cookie');
			if (cookieDesc && cookieDesc.configurable) {
				Object.defineProperty(document, 'cookie', {
					configurable: true,
					enumerable: true,
					get: function () {
						// console.log('getCookie');
						// 当同时开启了 ajax hook 和 cookie get hook，才需要把 document.cookie 的读取通过同步 JSBridge 调用从 NSHTTPCookieStorage 中读取 cookie。
						// 因为当非 ajax hook 情况下，说明是纯 WKWebView 的场景，那么 ajax 响应头里 Set-Cookie 只会存储在 WKCookie 里，所以此时是只能直接从 WKCookie 里读取 cookie 的。
						if (window.KKJSBridgeConfig.ajaxHook && window.KKJSBridgeConfig.cookieGetHook) {
							let cookieJson: any = window.KKJSBridge.syncCall(_KKJSBridgeCOOKIE.moduleName, 'cookie', {
								"url" : window.location.href
							});
							return cookieJson.cookie;
						}

						return cookieDesc.get.call(document);
					},
					set: function (val) {
						// console.log('setCookie');
						if (window.KKJSBridgeConfig.cookieSetHook) {// 如果开启 cookie set hook，则需要把 cookie 同步给 Native
							window.KKJSBridge.call(_KKJSBridgeCOOKIE.moduleName, 'setCookie', {
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

	public static ready() {
		window.KKJSBridge.call(_KKJSBridgeCOOKIE.moduleName, 'bridgeReady', {});
	}
}