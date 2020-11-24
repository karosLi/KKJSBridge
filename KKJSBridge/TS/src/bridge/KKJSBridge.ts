import { KKJSBridgeIframe } from "../util/KKJSBridgeUtil"

/**
 * 建立与 native 的数据通信
 */
export class KKJSBridge {
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