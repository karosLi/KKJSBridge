(function (global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
    typeof define === 'function' && define.amd ? define('lib/fetch.js', factory) :
    (global = global || self, global.KKJSBridge = factory());
}(this, (function () { 'use strict';

    /*! *****************************************************************************
    Copyright (c) Microsoft Corporation. All rights reserved.
    Licensed under the Apache License, Version 2.0 (the "License"); you may not use
    this file except in compliance with the License. You may obtain a copy of the
    License at http://www.apache.org/licenses/LICENSE-2.0

    THIS CODE IS PROVIDED ON AN *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
    WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
    MERCHANTABLITY OR NON-INFRINGEMENT.

    See the Apache Version 2.0 License for specific language governing permissions
    and limitations under the License.
    ***************************************************************************** */

    function __awaiter(thisArg, _arguments, P, generator) {
        return new (P || (P = Promise))(function (resolve, reject) {
            function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
            function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
            function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
            step((generator = generator.apply(thisArg, _arguments || [])).next());
        });
    }

    function __generator(thisArg, body) {
        var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
        return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
        function verb(n) { return function (v) { return step([n, v]); }; }
        function step(op) {
            if (f) throw new TypeError("Generator is already executing.");
            while (_) try {
                if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
                if (y = 0, t) op = [op[0] & 2, t.value];
                switch (op[0]) {
                    case 0: case 1: t = op; break;
                    case 4: _.label++; return { value: op[1], done: false };
                    case 5: _.label++; y = op[1]; op = [0]; continue;
                    case 7: op = _.ops.pop(); _.trys.pop(); continue;
                    default:
                        if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                        if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                        if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                        if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                        if (t[2]) _.ops.pop();
                        _.trys.pop(); continue;
                }
                op = body.call(thisArg, _);
            } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
            if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
        }
    }

    function __values(o) {
        var m = typeof Symbol === "function" && o[Symbol.iterator], i = 0;
        if (m) return m.call(o);
        return {
            next: function () {
                if (o && i >= o.length) o = void 0;
                return { value: o && o[i++], done: !o };
            }
        };
    }

    var support = {
      searchParams: 'URLSearchParams' in self,
      iterable: 'Symbol' in self && 'iterator' in Symbol,
      blob:
        'FileReader' in self &&
        'Blob' in self &&
        (function() {
          try {
            new Blob();
            return true
          } catch (e) {
            return false
          }
        })(),
      formData: 'FormData' in self,
      arrayBuffer: 'ArrayBuffer' in self
    };

    function isDataView(obj) {
      return obj && DataView.prototype.isPrototypeOf(obj)
    }

    if (support.arrayBuffer) {
      var viewClasses = [
        '[object Int8Array]',
        '[object Uint8Array]',
        '[object Uint8ClampedArray]',
        '[object Int16Array]',
        '[object Uint16Array]',
        '[object Int32Array]',
        '[object Uint32Array]',
        '[object Float32Array]',
        '[object Float64Array]'
      ];

      var isArrayBufferView =
        ArrayBuffer.isView ||
        function(obj) {
          return obj && viewClasses.indexOf(Object.prototype.toString.call(obj)) > -1
        };
    }

    function normalizeName(name) {
      if (typeof name !== 'string') {
        name = String(name);
      }
      if (/[^a-z0-9\-#$%&'*+.^_`|~!]/i.test(name) || name === '') {
        throw new TypeError('Invalid character in header field name')
      }
      return name.toLowerCase()
    }

    function normalizeValue(value) {
      if (typeof value !== 'string') {
        value = String(value);
      }
      return value
    }

    // Build a destructive iterator for the value list
    function iteratorFor(items) {
      var iterator = {
        next: function() {
          var value = items.shift();
          return {done: value === undefined, value: value}
        }
      };

      if (support.iterable) {
        iterator[Symbol.iterator] = function() {
          return iterator
        };
      }

      return iterator
    }

    function Headers(headers) {
      this.map = {};

      if (headers instanceof Headers) {
        headers.forEach(function(value, name) {
          this.append(name, value);
        }, this);
      } else if (Array.isArray(headers)) {
        headers.forEach(function(header) {
          this.append(header[0], header[1]);
        }, this);
      } else if (headers) {
        Object.getOwnPropertyNames(headers).forEach(function(name) {
          this.append(name, headers[name]);
        }, this);
      }
    }

    Headers.prototype.append = function(name, value) {
      name = normalizeName(name);
      value = normalizeValue(value);
      var oldValue = this.map[name];
      this.map[name] = oldValue ? oldValue + ', ' + value : value;
    };

    Headers.prototype['delete'] = function(name) {
      delete this.map[normalizeName(name)];
    };

    Headers.prototype.get = function(name) {
      name = normalizeName(name);
      return this.has(name) ? this.map[name] : null
    };

    Headers.prototype.has = function(name) {
      return this.map.hasOwnProperty(normalizeName(name))
    };

    Headers.prototype.set = function(name, value) {
      this.map[normalizeName(name)] = normalizeValue(value);
    };

    Headers.prototype.forEach = function(callback, thisArg) {
      for (var name in this.map) {
        if (this.map.hasOwnProperty(name)) {
          callback.call(thisArg, this.map[name], name, this);
        }
      }
    };

    Headers.prototype.keys = function() {
      var items = [];
      this.forEach(function(value, name) {
        items.push(name);
      });
      return iteratorFor(items)
    };

    Headers.prototype.values = function() {
      var items = [];
      this.forEach(function(value) {
        items.push(value);
      });
      return iteratorFor(items)
    };

    Headers.prototype.entries = function() {
      var items = [];
      this.forEach(function(value, name) {
        items.push([name, value]);
      });
      return iteratorFor(items)
    };

    if (support.iterable) {
      Headers.prototype[Symbol.iterator] = Headers.prototype.entries;
    }

    function consumed(body) {
      if (body.bodyUsed) {
        return Promise.reject(new TypeError('Already read'))
      }
      body.bodyUsed = true;
    }

    function fileReaderReady(reader) {
      return new Promise(function(resolve, reject) {
        reader.onload = function() {
          resolve(reader.result);
        };
        reader.onerror = function() {
          reject(reader.error);
        };
      })
    }

    function readBlobAsArrayBuffer(blob) {
      var reader = new FileReader();
      var promise = fileReaderReady(reader);
      reader.readAsArrayBuffer(blob);
      return promise
    }

    function readBlobAsText(blob) {
      var reader = new FileReader();
      var promise = fileReaderReady(reader);
      reader.readAsText(blob);
      return promise
    }

    function readArrayBufferAsText(buf) {
      var view = new Uint8Array(buf);
      var chars = new Array(view.length);

      for (var i = 0; i < view.length; i++) {
        chars[i] = String.fromCharCode(view[i]);
      }
      return chars.join('')
    }

    function bufferClone(buf) {
      if (buf.slice) {
        return buf.slice(0)
      } else {
        var view = new Uint8Array(buf.byteLength);
        view.set(new Uint8Array(buf));
        return view.buffer
      }
    }

    function Body() {
      this.bodyUsed = false;

      this._initBody = function(body) {
        /*
          fetch-mock wraps the Response object in an ES6 Proxy to
          provide useful test harness features such as flush. However, on
          ES5 browsers without fetch or Proxy support pollyfills must be used;
          the proxy-pollyfill is unable to proxy an attribute unless it exists
          on the object before the Proxy is created. This change ensures
          Response.bodyUsed exists on the instance, while maintaining the
          semantic of setting Request.bodyUsed in the constructor before
          _initBody is called.
        */
        this.bodyUsed = this.bodyUsed;
        this._bodyInit = body;
        if (!body) {
          this._bodyText = '';
        } else if (typeof body === 'string') {
          this._bodyText = body;
        } else if (support.blob && Blob.prototype.isPrototypeOf(body)) {
          this._bodyBlob = body;
        } else if (support.formData && FormData.prototype.isPrototypeOf(body)) {
          this._bodyFormData = body;
        } else if (support.searchParams && URLSearchParams.prototype.isPrototypeOf(body)) {
          this._bodyText = body.toString();
        } else if (support.arrayBuffer && support.blob && isDataView(body)) {
          this._bodyArrayBuffer = bufferClone(body.buffer);
          // IE 10-11 can't handle a DataView body.
          this._bodyInit = new Blob([this._bodyArrayBuffer]);
        } else if (support.arrayBuffer && (ArrayBuffer.prototype.isPrototypeOf(body) || isArrayBufferView(body))) {
          this._bodyArrayBuffer = bufferClone(body);
        } else {
          this._bodyText = body = Object.prototype.toString.call(body);
        }

        if (!this.headers.get('content-type')) {
          if (typeof body === 'string') {
            this.headers.set('content-type', 'text/plain;charset=UTF-8');
          } else if (this._bodyBlob && this._bodyBlob.type) {
            this.headers.set('content-type', this._bodyBlob.type);
          } else if (support.searchParams && URLSearchParams.prototype.isPrototypeOf(body)) {
            this.headers.set('content-type', 'application/x-www-form-urlencoded;charset=UTF-8');
          }
        }
      };

      if (support.blob) {
        this.blob = function() {
          var rejected = consumed(this);
          if (rejected) {
            return rejected
          }

          if (this._bodyBlob) {
            return Promise.resolve(this._bodyBlob)
          } else if (this._bodyArrayBuffer) {
            return Promise.resolve(new Blob([this._bodyArrayBuffer]))
          } else if (this._bodyFormData) {
            throw new Error('could not read FormData body as blob')
          } else {
            return Promise.resolve(new Blob([this._bodyText]))
          }
        };

        this.arrayBuffer = function() {
          if (this._bodyArrayBuffer) {
            return consumed(this) || Promise.resolve(this._bodyArrayBuffer)
          } else {
            return this.blob().then(readBlobAsArrayBuffer)
          }
        };
      }

      this.text = function() {
        var rejected = consumed(this);
        if (rejected) {
          return rejected
        }

        if (this._bodyBlob) {
          return readBlobAsText(this._bodyBlob)
        } else if (this._bodyArrayBuffer) {
          return Promise.resolve(readArrayBufferAsText(this._bodyArrayBuffer))
        } else if (this._bodyFormData) {
          throw new Error('could not read FormData body as text')
        } else {
          return Promise.resolve(this._bodyText)
        }
      };

      if (support.formData) {
        this.formData = function() {
          return this.text().then(decode)
        };
      }

      this.json = function() {
        return this.text().then(JSON.parse)
      };

      return this
    }

    // HTTP methods whose capitalization should be normalized
    var methods = ['DELETE', 'GET', 'HEAD', 'OPTIONS', 'POST', 'PUT'];

    function normalizeMethod(method) {
      var upcased = method.toUpperCase();
      return methods.indexOf(upcased) > -1 ? upcased : method
    }

    function Request(input, options) {
      options = options || {};
      var body = options.body;

      if (input instanceof Request) {
        if (input.bodyUsed) {
          throw new TypeError('Already read')
        }
        this.url = input.url;
        this.credentials = input.credentials;
        if (!options.headers) {
          this.headers = new Headers(input.headers);
        }
        this.method = input.method;
        this.mode = input.mode;
        this.signal = input.signal;
        if (!body && input._bodyInit != null) {
          body = input._bodyInit;
          input.bodyUsed = true;
        }
      } else {
        this.url = String(input);
      }

      this.credentials = options.credentials || this.credentials || 'same-origin';
      if (options.headers || !this.headers) {
        this.headers = new Headers(options.headers);
      }
      this.method = normalizeMethod(options.method || this.method || 'GET');
      this.mode = options.mode || this.mode || null;
      this.signal = options.signal || this.signal;
      this.referrer = null;

      if ((this.method === 'GET' || this.method === 'HEAD') && body) {
        throw new TypeError('Body not allowed for GET or HEAD requests')
      }
      this._initBody(body);
    }

    Request.prototype.clone = function() {
      return new Request(this, {body: this._bodyInit})
    };

    function decode(body) {
      var form = new FormData();
      body
        .trim()
        .split('&')
        .forEach(function(bytes) {
          if (bytes) {
            var split = bytes.split('=');
            var name = split.shift().replace(/\+/g, ' ');
            var value = split.join('=').replace(/\+/g, ' ');
            form.append(decodeURIComponent(name), decodeURIComponent(value));
          }
        });
      return form
    }

    function parseHeaders(rawHeaders) {
      var headers = new Headers();
      // Replace instances of \r\n and \n followed by at least one space or horizontal tab with a space
      // https://tools.ietf.org/html/rfc7230#section-3.2
      var preProcessedHeaders = rawHeaders.replace(/\r?\n[\t ]+/g, ' ');
      preProcessedHeaders.split(/\r?\n/).forEach(function(line) {
        var parts = line.split(':');
        var key = parts.shift().trim();
        if (key) {
          var value = parts.join(':').trim();
          headers.append(key, value);
        }
      });
      return headers
    }

    Body.call(Request.prototype);

    function Response(bodyInit, options) {
      if (!options) {
        options = {};
      }

      this.type = 'default';
      this.status = options.status === undefined ? 200 : options.status;
      this.ok = this.status >= 200 && this.status < 300;
      this.statusText = 'statusText' in options ? options.statusText : '';
      this.headers = new Headers(options.headers);
      this.url = options.url || '';
      this._initBody(bodyInit);
    }

    Body.call(Response.prototype);

    Response.prototype.clone = function() {
      return new Response(this._bodyInit, {
        status: this.status,
        statusText: this.statusText,
        headers: new Headers(this.headers),
        url: this.url
      })
    };

    Response.error = function() {
      var response = new Response(null, {status: 0, statusText: ''});
      response.type = 'error';
      return response
    };

    var redirectStatuses = [301, 302, 303, 307, 308];

    Response.redirect = function(url, status) {
      if (redirectStatuses.indexOf(status) === -1) {
        throw new RangeError('Invalid status code')
      }

      return new Response(null, {status: status, headers: {location: url}})
    };

    var DOMException = self.DOMException;
    try {
      new DOMException();
    } catch (err) {
      DOMException = function(message, name) {
        this.message = message;
        this.name = name;
        var error = Error(message);
        this.stack = error.stack;
      };
      DOMException.prototype = Object.create(Error.prototype);
      DOMException.prototype.constructor = DOMException;
    }

    function fetch(input, init) {
      return new Promise(function(resolve, reject) {
        var request = new Request(input, init);

        if (request.signal && request.signal.aborted) {
          return reject(new DOMException('Aborted', 'AbortError'))
        }

        var xhr = new XMLHttpRequest();

        function abortXhr() {
          xhr.abort();
        }

        xhr.onload = function() {
          var options = {
            status: xhr.status,
            statusText: xhr.statusText,
            headers: parseHeaders(xhr.getAllResponseHeaders() || '')
          };
          options.url = 'responseURL' in xhr ? xhr.responseURL : options.headers.get('X-Request-URL');
          var body = 'response' in xhr ? xhr.response : xhr.responseText;
          setTimeout(function() {
            resolve(new Response(body, options));
          }, 0);
        };

        xhr.onerror = function() {
          setTimeout(function() {
            reject(new TypeError('Network request failed'));
          }, 0);
        };

        xhr.ontimeout = function() {
          setTimeout(function() {
            reject(new TypeError('Network request failed'));
          }, 0);
        };

        xhr.onabort = function() {
          setTimeout(function() {
            reject(new DOMException('Aborted', 'AbortError'));
          }, 0);
        };

        function fixUrl(url) {
          try {
            return url === '' && self.location.href ? self.location.href : url
          } catch (e) {
            return url
          }
        }

        xhr.open(request.method, fixUrl(request.url), true);

        if (request.credentials === 'include') {
          xhr.withCredentials = true;
        } else if (request.credentials === 'omit') {
          xhr.withCredentials = false;
        }

        if ('responseType' in xhr) {
          if (support.blob) {
            xhr.responseType = 'blob';
          } else if (
            support.arrayBuffer &&
            request.headers.get('Content-Type').indexOf('application/octet-stream') !== -1
          ) {
            xhr.responseType = 'arraybuffer';
          }
        }

        request.headers.forEach(function(value, name) {
          xhr.setRequestHeader(name, value);
        });

        if (request.signal) {
          request.signal.addEventListener('abort', abortXhr);

          xhr.onreadystatechange = function() {
            // DONE (success or failure)
            if (xhr.readyState === 4) {
              request.signal.removeEventListener('abort', abortXhr);
            }
          };
        }

        xhr.send(typeof request._bodyInit === 'undefined' ? null : request._bodyInit);
      })
    }

    fetch.polyfill = true;

    // 先备份
    var originHeaders = self.Headers;
    var originRequest = self.Request;
    var originResponse = self.Response;
    var originFetch = self.fetch;

    if (!self.fetch) {
      self.fetch = fetch;
      self.Headers = Headers;
      self.Request = Request;
      self.Response = Response;
    }

    function enableFetchHook(enable) {
      if (originFetch) { // 如果当前系统支持 fetch，才需要 hook
        if (enable) {
          // 开启 fetch hook
          self.fetch = fetch;
          self.Headers = Headers;
          self.Request = Request;
          self.Response = Response;
        } else {
          // 关闭 fetch hook
          self.fetch = originFetch;
          self.Headers = originHeaders;
          self.Request = originRequest;
          self.Response = originResponse;
        }
      }
    }

    var init = function () {
        if (window.KKJSBridge) {
            return;
        }
        var KKJSBridge = /** @class */ (function () {
            function KKJSBridge() {
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
            KKJSBridge.prototype.callNative = function (module, method, data, callback) {
                var message = {
                    module: module || 'default',
                    method: method,
                    data: data,
                    callbackId: null
                };
                if (callback) {
                    // 拼装 callbackId
                    var callbackId = 'cb_' + message.module + '_' + method + '_' + (this.uniqueId++) + '_' + new Date().getTime();
                    // 缓存 callback，用于在 Native 处理完消息后，通知 H5
                    this.callbackCache[callbackId] = callback;
                    // 追加 callbackId 属性
                    message.callbackId = callbackId;
                }
                // 发送消息给 Native
                window.webkit.messageHandlers.KKJSBridgeMessage.postMessage(message);
            };
            /**
             * 用于处理来自 Native 的消息
             * @param callbackMessage 回调消息
             */
            KKJSBridge.prototype._handleMessageFromNative = function (messageString) {
                var callbackMessage = JSON.parse(messageString);
                if (callbackMessage.messageType === "callback" /* Callback */) { // 回调消息
                    var callback = this.callbackCache[callbackMessage.callbackId];
                    if (callback) { // 执行 callback 回调，并删除缓存的 callback
                        callback(callbackMessage.data);
                        this.callbackCache[callbackMessage.callbackId] = null;
                        delete this.callbackCache[callbackMessage.callbackId];
                    }
                }
                else if (callbackMessage.messageType === "event" /* Event */) { // 事件消息
                    // 支持批量事件调用
                    var obsevers = this.eventCallbackCache[callbackMessage.eventName];
                    if (obsevers) {
                        for (var i = 0; i < obsevers.length; i++) {
                            var eventCallback = obsevers[i];
                            if (eventCallback) {
                                eventCallback(callbackMessage.data);
                            }
                        }
                    }
                }
            };
            /**
             * 调用方法
             * @param module 模块
             * @param method 方法
             * @param data 数据
             * @param callback 调用回调
             */
            KKJSBridge.prototype.call = function (module, method, data, callback) {
                this.callNative(module, method, data, callback);
            };
            /**
             * 监听事件
             * @param eventName 事件名字
             * @param callback 事件回调
             */
            KKJSBridge.prototype.on = function (eventName, callback) {
                // 使用数组，支持多个观察者
                var obsevers = this.eventCallbackCache[eventName];
                if (obsevers) {
                    obsevers.push(callback);
                }
                else {
                    obsevers = [callback];
                    this.eventCallbackCache[eventName] = obsevers;
                }
            };
            /**
             * 取消监听事件
             * @param eventName 事件名字
             */
            KKJSBridge.prototype.off = function (eventName) {
                var obsevers = this.eventCallbackCache[eventName];
                if (obsevers && obsevers.length > 0) {
                    obsevers.splice(0, obsevers.length);
                }
            };
            return KKJSBridge;
        }());
        // 初始化 KKJSBridge
        var KKJSBridgeInstance = new KKJSBridge();
        /**
         * KKJSBridge 工具
         */
        var KKJSBridgeUtil = /** @class */ (function () {
            function KKJSBridgeUtil() {
            }
            KKJSBridgeUtil.convertFormDataToJson = function (formData, callback) {
                var _this = this;
                var promise = new Promise(function (resolve, reject) { return __awaiter(_this, void 0, void 0, function () {
                    var formDataJson, formDataFileKeys, formDatas, i, pair, key, value, fileName, singleKeyValue, formDataFile, _a, _b, pair, key, value, singleKeyValue, formDataFile, e_1_1;
                    var e_1, _c;
                    return __generator(this, function (_d) {
                        switch (_d.label) {
                            case 0:
                                formDataJson = {};
                                formDataFileKeys = [];
                                formDatas = [];
                                if (!formData._entries) return [3 /*break*/, 7];
                                i = 0;
                                _d.label = 1;
                            case 1:
                                if (!(i < formData._entries.length)) return [3 /*break*/, 6];
                                pair = formData._entries[i];
                                key = pair[0];
                                value = pair[1];
                                fileName = pair.length > 2 ? pair[2] : null;
                                singleKeyValue = [];
                                singleKeyValue.push(key);
                                if (!(value instanceof File || value instanceof Blob)) return [3 /*break*/, 3];
                                return [4 /*yield*/, KKJSBridgeUtil.convertFileToJson(value)];
                            case 2:
                                formDataFile = _d.sent();
                                if (fileName) { // 文件名需要处理下
                                    formDataFile.name = fileName;
                                }
                                singleKeyValue.push(formDataFile);
                                formDataFileKeys.push(key);
                                return [3 /*break*/, 4];
                            case 3:
                                singleKeyValue.push(value);
                                _d.label = 4;
                            case 4:
                                formDatas.push(singleKeyValue);
                                _d.label = 5;
                            case 5:
                                i++;
                                return [3 /*break*/, 1];
                            case 6: return [3 /*break*/, 16];
                            case 7:
                                _d.trys.push([7, 14, 15, 16]);
                                _a = __values(formData.entries()), _b = _a.next();
                                _d.label = 8;
                            case 8:
                                if (!!_b.done) return [3 /*break*/, 13];
                                pair = _b.value;
                                key = pair[0];
                                value = pair[1];
                                singleKeyValue = [];
                                singleKeyValue.push(key);
                                if (!(value instanceof File || value instanceof Blob)) return [3 /*break*/, 10];
                                return [4 /*yield*/, KKJSBridgeUtil.convertFileToJson(value)];
                            case 9:
                                formDataFile = _d.sent();
                                singleKeyValue.push(formDataFile);
                                formDataFileKeys.push(key);
                                return [3 /*break*/, 11];
                            case 10:
                                singleKeyValue.push(value);
                                _d.label = 11;
                            case 11:
                                formDatas.push(singleKeyValue);
                                _d.label = 12;
                            case 12:
                                _b = _a.next();
                                return [3 /*break*/, 8];
                            case 13: return [3 /*break*/, 16];
                            case 14:
                                e_1_1 = _d.sent();
                                e_1 = { error: e_1_1 };
                                return [3 /*break*/, 16];
                            case 15:
                                try {
                                    if (_b && !_b.done && (_c = _a.return)) _c.call(_a);
                                }
                                finally { if (e_1) throw e_1.error; }
                                return [7 /*endfinally*/];
                            case 16:
                                formDataJson['fileKeys'] = formDataFileKeys;
                                formDataJson['formData'] = formDatas;
                                resolve(formDataJson);
                                return [2 /*return*/];
                        }
                    });
                }); });
                promise.then(function (json) {
                    callback(json);
                }).catch(function (error) {
                    console.log(error);
                });
            };
            /**
             * 读取单个文件数据，并转成 base64，最后返回 json 对象
             * @param file
             */
            KKJSBridgeUtil.convertFileToJson = function (file) {
                return new Promise(function (resolve, reject) {
                    var reader = new FileReader();
                    reader.readAsDataURL(file);
                    reader.onload = function (ev) {
                        var base64 = ev.target.result;
                        var formDataFile = {
                            name: file instanceof File ? file.name : '',
                            lastModified: file instanceof File ? file.lastModified : 0,
                            size: file.size,
                            type: file.type,
                            data: base64
                        };
                        resolve(formDataFile);
                        return null;
                    };
                    reader.onerror = function (ev) {
                        reject(Error("formdata 表单读取文件数据失败"));
                        return null;
                    };
                });
            };
            return KKJSBridgeUtil;
        }());
        /**
         * 生成 AJAX Proxy
         * https://github.com/wendux/Ajax-hook/blob/master/src/ajaxhook.js
         */
        function hookAjaxProxy() {
            var ob = {};
            //Save original XMLHttpRequest as RealXMLHttpRequest
            var realXhr = "RealXMLHttpRequest";
            //Call this function will override the `XMLHttpRequest` object
            ob.hookAjax = function (proxy) {
                // Avoid double hook
                window[realXhr] = window[realXhr] || XMLHttpRequest;
                window.XMLHttpRequest = function () {
                    var xhr = new window[realXhr];
                    // We shouldn't hook XMLHttpRequest.prototype because we can't
                    // guarantee that all attributes are on the prototype。
                    // Instead, hooking XMLHttpRequest instance can avoid this problem.
                    for (var attr in xhr) {
                        var type = "";
                        try {
                            type = typeof xhr[attr]; // May cause exception on some browser
                        }
                        catch (e) {
                        }
                        if (type === "function") {
                            // hook methods of xhr, such as `open`、`send` ...
                            this[attr] = hookFunction(attr);
                        }
                        else {
                            Object.defineProperty(this, attr, {
                                get: getterFactory(attr),
                                set: setterFactory(attr),
                                enumerable: true
                            });
                        }
                    }
                    this.xhr = xhr;
                };
                // Generate getter for attributes of xhr
                function getterFactory(attr) {
                    return function () {
                        var v = this.hasOwnProperty(attr + "_") ? this[attr + "_"] : this.xhr[attr];
                        var attrGetterHook = (proxy[attr] || {})["getter"];
                        return attrGetterHook && attrGetterHook(v, this) || v;
                    };
                }
                // Generate setter for attributes of xhr; by this we have an opportunity
                // to hook event callbacks （eg: `onload`） of xhr;
                function setterFactory(attr) {
                    return function (v) {
                        var xhr = this.xhr;
                        var that = this;
                        var hook = proxy[attr];
                        if (typeof hook === "function") {
                            // hook  event callbacks such as `onload`、`onreadystatechange`...
                            xhr[attr] = function () {
                                proxy[attr](that) || v.apply(xhr, arguments);
                            };
                        }
                        else {
                            //If the attribute isn't writable, generate proxy attribute
                            var attrSetterHook = (hook || {})["setter"];
                            v = attrSetterHook && attrSetterHook(v, that) || v;
                            try {
                                xhr[attr] = v;
                            }
                            catch (e) {
                                this[attr + "_"] = v;
                            }
                        }
                    };
                }
                // Hook methods of xhr.
                function hookFunction(fun) {
                    return function () {
                        var args = [].slice.call(arguments);
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
                    };
                }
                // Return the real XMLHttpRequest
                return window[realXhr];
            };
            // Cancel hook
            ob.unHookAjax = function () {
                if (window[realXhr])
                    XMLHttpRequest = window[realXhr];
                window[realXhr] = undefined;
            };
            return ob;
        }
        window._hookAjaxProxy = hookAjaxProxy();
        /**
         * Hook FormData，由于低版本的 FormData 没有支持 entries() 等遍历 api，所以只是在 ajax send 里遍历，是无法获取到具体的值的，
         * 所以针对低版本的 iOS 系统做 Hook FormData 处理。
         */
        var originAppend = window.FormData.prototype['append'];
        var originEntries = window.FormData.prototype['entries'];
        if (!originEntries) {
            window.FormData.prototype['append'] = function () {
                if (!this._entries) {
                    this._entries = [];
                }
                this._entries.push(arguments);
                return originAppend.apply(this, arguments);
            };
        }
        /**
         * AJAX Proxy 配置
         */
        var _XHR = /** @class */ (function () {
            function _XHR() {
            }
            // 静态属性和方法
            _XHR.moduleName = 'ajax';
            _XHR.globalId = Math.floor(Math.random() * 1000);
            _XHR.cache = [];
            /**
             * 缓存 ajax 代理对象
             */
            _XHR.cacheXHRIfNeed = function (xhr) {
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
                    xhr.id = _XHR.globalId++; // 请求 id 计数加 1
                    _XHR.cache[xhr.id] = xhr;
                    xhr.isCached = true;
                }
            };
            /**
             * 用于处理来自 native 的异步回调
             */
            _XHR.setProperties = function (jsonString) {
                var jsonObj = JSON.parse(jsonString);
                var id = jsonObj.id;
                var xhr = _XHR.cache[id];
                if (jsonObj.readyState === xhr.DONE) {
                    // 防止重复利用 xhr 对象发送请求而导致 id 不变的问题
                    xhr.isCached = false;
                }
                if (xhr) {
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
            };
            /**
             * 删除已经已经处理过的请求
             */
            _XHR.deleteObject = function (id) {
                if (_XHR.cache[id]) {
                    delete _XHR.cache[id];
                }
            };
            return _XHR;
        }());
        window._XHR = _XHR;
        function hookAjax() {
            /**
             * https://developer.mozilla.org/zh-CN/docs/Web/API/XMLHttpRequest
             *
             * 1、hook 之后，每个 XMLHttpRequest 代理对象里面都会对应一个真正的 XMLHttpRequest 对象。
             * 2、支持基本属性 hook，事件属性回调 hook 和函数 hook。
             * 3、基本属性和事件属性 hook 里的入参 xhr 参数是一个 XMLHttpRequest 代理对象。而函数 hook 里的入参 xhr 是一个实际 XMLHttpRequest。 所以可以给代理对象添加属性，然后在其他 hook 方法里共享属性。
             * 4、函数 hook 返回 true 时，将会阻断真正的 XMLHttpRequest 的实际函数请求。
             *
             **/
            window._hookAjaxProxy.hookAjax({
                // 拦截属性
                readyState: {
                    getter: function (v, xhr) {
                        return xhr.callbackProperties.readyState;
                    }
                },
                status: {
                    getter: function (v, xhr) {
                        return xhr.callbackProperties.status;
                    }
                },
                statusText: {
                    getter: function (v, xhr) {
                        return xhr.callbackProperties.statusText;
                    }
                },
                responseText: {
                    getter: function (v, xhr) {
                        return xhr.callbackProperties.responseText;
                    }
                },
                response: {
                    getter: function (v, xhr) {
                        return xhr.callbackProperties.responseText;
                    }
                },
                //拦截回调
                onreadystatechange: function (xhr) {
                    // nothing
                },
                onload: function (xhr) {
                    // nothing
                },
                //拦截方法
                open: function (arg, xhr) {
                    console.log("open called: method:%s,url:%s,async:%s", arg[0], arg[1], arg[2]);
                    var method = arg[0];
                    var url = arg[1];
                    var async = arg[2];
                    _XHR.cacheXHRIfNeed(this);
                    window.KKJSBridge.call(_XHR.moduleName, 'open', {
                        "id": this.id,
                        "method": method,
                        "url": url,
                        "scheme": window.location.protocol,
                        "host": window.location.hostname,
                        "port": window.location.port,
                        "href": window.location.href,
                        "referer": document.referrer != "" ? document.referrer : null,
                        "useragent": navigator.userAgent,
                        "async": async,
                    });
                    return true;
                },
                send: function (arg, xhr) {
                    var _this = this;
                    console.log("send called:", arg[0]);
                    var data = arg[0];
                    if (data) {
                        if (data instanceof Uint8Array) {
                            // 特殊处理字节数据
                            data = Array.from(data);
                            window.KKJSBridge.call(_XHR.moduleName, 'send', {
                                "id": this.id,
                                "isByteData": true,
                                "data": data
                            });
                        }
                        else if (data instanceof FormData) {
                            // formData 表单
                            KKJSBridgeUtil.convertFormDataToJson(data, function (json) {
                                window.KKJSBridge.call(_XHR.moduleName, 'send', {
                                    "id": _this.id,
                                    "isFormData": true,
                                    "data": json
                                });
                            });
                        }
                        else {
                            window.KKJSBridge.call(_XHR.moduleName, 'send', {
                                "id": this.id,
                                "data": data
                            });
                        }
                    }
                    else {
                        window.KKJSBridge.call(_XHR.moduleName, 'send', {
                            "id": this.id
                        });
                    }
                    return true;
                },
                overrideMimeType: function (arg, xhr) {
                    // console.log("overrideMimeType called:", arg[0]);
                    _XHR.cacheXHRIfNeed(this);
                    var mimetype = arg[0];
                    window.KKJSBridge.call(_XHR.moduleName, 'overrideMimeType', {
                        "id": this.id,
                        "mimetype": mimetype
                    });
                    return true;
                },
                abort: function (arg, xhr) {
                    console.log("abort called");
                    window.KKJSBridge.call(_XHR.moduleName, 'abort', {
                        "id": this.id
                    });
                    return true;
                },
                setRequestHeader: function (arg, xhr) {
                    // console.log("setRequestHeader called:", arg[0], arg[1]);
                    var headerName = arg[0];
                    var headerValue = arg[1];
                    window.KKJSBridge.call(_XHR.moduleName, 'setRequestHeader', {
                        "id": this.id,
                        "headerName": headerName,
                        "headerValue": headerValue
                    });
                    return true;
                },
                getAllResponseHeaders: function (arg, xhr) {
                    // console.log("getAllResponseHeaders called");
                    var strHeaders = '';
                    for (var name_1 in this.callbackProperties.headers) {
                        strHeaders += (name_1 + ": " + this.callbackProperties.headers[name_1] + "\r\n");
                    }
                    return strHeaders;
                },
                getResponseHeader: function (arg, xhr) {
                    console.log("getResponseHeader called:", arg[0]);
                    var headerName = arg[0];
                    var strHeaders = '';
                    var upperCaseHeaderName = headerName.toUpperCase();
                    for (var name_2 in this.callbackProperties.headers) {
                        if (upperCaseHeaderName == name_2.toUpperCase())
                            strHeaders = this.callbackProperties.headers[name_2];
                    }
                    return strHeaders;
                },
            });
            // 开启 fetch hook
            enableFetchHook(true);
        }
        function unHookAjax() {
            window._hookAjaxProxy.unHookAjax();
            // 关闭 fetch hook
            enableFetchHook(false);
        }
        /**
         * hook document.cookie
         */
        var _COOKIE = /** @class */ (function () {
            function _COOKIE() {
            }
            // 静态属性和方法
            _COOKIE.moduleName = 'cookie';
            /**
             * 通过重新定义 cookie 属性来进行 cookie hook
             */
            _COOKIE.hookCookie = function () {
                try {
                    var cookieDesc = Object.getOwnPropertyDescriptor(Document.prototype, 'cookie') ||
                        Object.getOwnPropertyDescriptor(HTMLDocument.prototype, 'cookie');
                    if (cookieDesc && cookieDesc.configurable) {
                        Object.defineProperty(document, 'cookie', {
                            configurable: true,
                            enumerable: true,
                            get: function () {
                                // console.log('getCookie');
                                return cookieDesc.get.call(document);
                            },
                            set: function (val) {
                                // console.log('setCookie');
                                cookieDesc.set.call(document, val);
                                window.KKJSBridge.call(_COOKIE.moduleName, 'setCookie', {
                                    "cookie": val
                                });
                            }
                        });
                    }
                }
                catch (e) {
                    console.log('this browser does not support reconfigure document.cookie property', e);
                }
            };
            return _COOKIE;
        }());
        window._COOKIE = _COOKIE;
        window._COOKIE.hookCookie();
        /**
         * KKJSBridge 配置
         */
        var KKJSBridgeConfig = /** @class */ (function () {
            function KKJSBridgeConfig() {
            }
            KKJSBridgeConfig.init = function () {
                window.KKJSBridge = KKJSBridgeInstance; // 设置新的 JSBridge 作为全局对象
            };
            /**
             * 开启 ajax hook
             */
            KKJSBridgeConfig.enableAjaxHook = function (enable) {
                if (enable) {
                    hookAjax();
                }
                else {
                    unHookAjax();
                }
            };
            /**
             * bridge Ready
             */
            KKJSBridgeConfig.bridgeReady = function () {
                // 告诉 H5 新的 KKJSBridge 已经 ready
                var KKJSBridgeReadyEvent = document.createEvent("Events");
                KKJSBridgeReadyEvent.initEvent("KKJSBridgeReady");
                document.dispatchEvent(KKJSBridgeReadyEvent);
            };
            return KKJSBridgeConfig;
        }());
        window.KKJSBridgeConfig = KKJSBridgeConfig;
        window.KKJSBridgeConfig.init(); // JSBridge 配置初始化
        // window.KKJSBridgeConfig.enableAjaxHook(true); // 默认不开启 ajax hook
        window.KKJSBridgeConfig.bridgeReady();
    };
    init();
    var indexold = window.KKJSBridge;

    return indexold;

})));
