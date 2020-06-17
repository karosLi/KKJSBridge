/**
 * 当 H5 还在使用 WebViewJavascriptBridge（基于 iframe 通信） 框架时，可以通过下方代码来兼容 WebViewJavascriptBridge。这样可以在不用改动 H5 任何代码，就可以无缝支持新的 JSBridge。
 * 如果使用不是 WebViewJavascriptBridge 这样的框架，兼容的原理也是类似的。
 */
; (function(window) {
   // 声明 WebViewJavascriptBridge 在函数体作用域里，这样就不会污染全局作用域
   var WebViewJavascriptBridge = {
     init: function (func) {
     },
     registerHandler: function (handlerName, handler) {
       window.KKJSBridgeInstance.on(handlerName, handler);
     },
     callHandler: function (handlerName, data, responseCallback) {
       window.KKJSBridgeInstance.call(null, handlerName, data, responseCallback);
     }
   };
   window.WebViewJavascriptBridge = WebViewJavascriptBridge;
   
   // 告诉 H5， WebViewJavascriptBridge 已经 ready
   var WebViewJavascriptBridgeReadyEvent = document.createEvent("Events");
   WebViewJavascriptBridgeReadyEvent.initEvent("WebViewJavascriptBridgeReady");
   document.dispatchEvent(WebViewJavascriptBridgeReadyEvent);
})(window);
