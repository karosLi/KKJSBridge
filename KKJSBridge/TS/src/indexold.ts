/// <reference path="../types/index.d.ts" />
import * as FetchHook from "./lib/fetch.js"
import { KKJSBridgeIframe } from "./util/KKJSBridgeUtil"
import { KKJSBridge } from "./bridge/KKJSBridge"
import { _KKJSBridgeFormData } from "./hook/KKJSBridgeFormDataHook"
import { _KKJSBridgeCOOKIE } from "./hook/KKJSBridgeCookieHook"
import { _KKJSBridgeXHR } from "./hook/KKJSBridgeAjaxHook"
import { _KKJSBridgeSendBeaconHook } from "./hook/KKJSBridgeSendBeaconHook"

var init = function() {
  if (window.KKJSBridge) {
    return;
  }

  /**
   * KKJSBridge 配置
   */
  class KKJSBridgeConfig {
    public static cookieSetHook: boolean = true;
    public static cookieGetHook: boolean = true;

    /**
     * 开启 ajax hook
     */
    public static enableAjaxHook: Function = (enable: boolean) => {
      if (enable) {
        window._KKJSBridgeXHR.enableAjaxHook(true);
        FetchHook.enableFetchHook(true);
      } else {
        window._KKJSBridgeXHR.enableAjaxHook(false);
        FetchHook.enableFetchHook(false);
      }
    };

    /**
     * 开启 cookie set hook
     */
    public static enableCookieSetHook: Function = (enable: boolean) => {
      KKJSBridgeConfig.cookieSetHook = enable;
    };

    /**
     * 开启 cookie get hook
     */
    public static enableCookieGetHook: Function = (enable: boolean) => {
      KKJSBridgeConfig.cookieGetHook = enable;
    };

    /**
     * bridge Ready
     */
    public static bridgeReady: Function = () => {
      _KKJSBridgeCOOKIE.ready();
      // 告诉 H5 新的 KKJSBridge 已经 ready
      let KKJSBridgeReadyEvent: Event = document.createEvent("Events");
      KKJSBridgeReadyEvent.initEvent("KKJSBridgeReady");
      document.dispatchEvent(KKJSBridgeReadyEvent);
    };
  }

  // 初始化 KKJSBridge 并设为全局对象
  window.KKJSBridge = new KKJSBridge();
  // 设置 KKJSBridgeConfig 为全局对象
  window.KKJSBridgeConfig = KKJSBridgeConfig;
  // 设置 _KKJSBridgeXHR 为全局对象
  window._KKJSBridgeXHR = _KKJSBridgeXHR;

  // iframe 内处理来自父 window 的消息
  KKJSBridgeIframe.addMessageListener();
  KKJSBridgeIframe.addAjaxMessageListener();
  // 安装 iframe hook： 设置 iframe 的 sandbox 属性
  KKJSBridgeIframe.setupHook();

  // 安装 formData hook
  _KKJSBridgeFormData.setupHook();

  // 安装 cookie hook
  _KKJSBridgeCOOKIE.setupHook();

  // 安装 sendBeacon hook
  _KKJSBridgeSendBeaconHook.setupHook();

  // 安装 ajax hook
  _KKJSBridgeXHR.setupHook();
  
  // JSBridge 安装完毕
  window.KKJSBridgeConfig.bridgeReady();
};
init();
export default window.KKJSBridge;

