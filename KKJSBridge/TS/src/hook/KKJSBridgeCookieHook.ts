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
						if (window.KKJSBridgeConfig.cookieHook) {// 如果开启 cookie hook，则从 Native 读取 cookie
							let cookieJson: any = window.KKJSBridge.syncCall(_KKJSBridgeCOOKIE.moduleName, 'cookie', {
								"url" : window.location.href
							});
							return cookieJson.cookie;
						}

						return cookieDesc.get.call(document);
					},
					set: function (val) {
						// console.log('setCookie');
						if (window.KKJSBridgeConfig.cookieHook) {// 如果开启 cookie hook，则需要把 cookie 同步给 Native
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