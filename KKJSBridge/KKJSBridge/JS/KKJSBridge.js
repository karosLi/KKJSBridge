(function (global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
    typeof define === 'function' && define.amd ? define('lib/fetch.js', factory) :
    (global = global || self, global.KKJSBridge = factory());
}(this, (function () { 'use strict';
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
                // 处理有 iframe 的情况
                var iframes = document.querySelectorAll("iframe");
                if (iframes) {
                    var len = iframes.length;
                    for (var i = 0; i < len; i++) {
                        iframes[i].contentWindow.KKJSBridge._handleMessageFromNative(messageString);
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
            /**
              把 arraybuffer 转成 base64
            */
            KKJSBridgeUtil.convertArrayBufferToBase64 = function (arraybuffer) {
                var uint8Array = new Uint8Array(arraybuffer);
                var charCode = "";
                var length = uint8Array.byteLength;
                for (var i = 0; i < length; i++) {
                    charCode += String.fromCharCode(uint8Array[i]);
                }
                // 字符串转成base64
                return window.btoa(charCode);
            };
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
         * AJAX 相关方法
         */
        var _XHR = /** @class */ (function () {
            function _XHR() {
            }
            // 静态属性和方法
            _XHR.moduleName = 'ajax';
            _XHR.globalId = Math.floor(Math.random() * 100000);
            _XHR.callbackCache = [];
            /**
             * 生成 ajax 请求唯一id
             */
            _XHR.generateXHRRequestId = function () {
                return (new Date).getTime() + "_" + _XHR.globalId++; // 时间戳 + 当前上下文唯一id，生成请求id
            };
            /**
             * 给表单生成新的 action
             */
            _XHR.generateNewActionForForm = function (form, requestId) {
                var orignAction = form.action;
                // 通过 a 标签来辅助拼接新的 action
                var aTag = document.createElement("a");
                aTag.href = orignAction;
                var search = aTag.search ? aTag.search : "";
                var hash = aTag.hash ? aTag.hash : "";
                if (/KKJSBridge-RequestId/.test(orignAction)) { // 防止重复追加 requestId
                    aTag.search = aTag.search.replace(/KKJSBridge-RequestId=(\d+_\d+)/, "KKJSBridge-RequestId=" + requestId);
                }
                else if (aTag.search && aTag.search.length > 0) {
                    var s = aTag.search;
                    if (/KKJSBridge-RequestId/.test(s)) { // 防止重复追加 requestId
                        aTag.search = s.replace(/KKJSBridge-RequestId=(\d+_\d+)/, "KKJSBridge-RequestId=" + requestId);
                    }
                    else {
                        aTag.search = s + "&KKJSBridge-RequestId=" + requestId;
                    }
                }
                else {
                    aTag.search = "?KKJSBridge-RequestId=" + requestId;
                }
                var url = orignAction.replace(search, "").replace(hash, "");
                if ("#" === url.trim()) {
                    url = "";
                }
                var newAction = url + aTag.search + aTag.hash;
                form.action = newAction;
            };
            /**
             * 发送 body 到 native 侧缓存起来
             * @param xhr
             * @param originMethod
             * @param originArguments
             * @param body
             */
            _XHR.sendBodyToNativeForCache = function (target, originMethod, originArguments, request) {
                var requestId = target.requestId;
                var cacheCallback = {
                    requestId: requestId,
                    callback: function () {
                        if (target instanceof XMLHttpRequest) { // ajax
                            // 发送之前设置自定义请求头，好让 native 拦截并从缓存里获取 body
                            target.setRequestHeader("KKJSBridge-RequestId", requestId);
                        }
                        else if (target instanceof HTMLFormElement) { // 表单 submit
                            // 发送之前修改 action，让 action 带上 requestId
                            _XHR.generateNewActionForForm(target, requestId);
                        }
                        // 调用原始 send 方法 
                        return originMethod.apply(target, originArguments);
                    }
                };
                // 缓存 callbcak
                _XHR.callbackCache[requestId] = cacheCallback;
                // 发送 body 请求到 native
                window.KKJSBridge.call(_XHR.moduleName, 'cacheAJAXBody', request, function (message) {
                    // 处理 native 侧缓存完毕后的消息
                    var callbackFromNative = message;
                    var requestId = callbackFromNative.requestId;
                    // 通过请求 id，找到原始方法并调用
                    if (_XHR.callbackCache[requestId]) {
                        var callbackFromNative_1 = _XHR.callbackCache[requestId];
                        if (callbackFromNative_1.callback) {
                            callbackFromNative_1.callback();
                        }
                        delete _XHR.callbackCache[requestId];
                    }
                });
            };
            return _XHR;
        }());
        window._XHR = _XHR;
        /**
         * 只 hook open/send 方法
         */
        var originOpen = XMLHttpRequest.prototype.open;
        XMLHttpRequest.prototype.open = function (method, url, async, username, password) {
            var args = [].slice.call(arguments);
            var xhr = this;
            // 生成唯一请求id
            xhr.requestId = _XHR.generateXHRRequestId();
            xhr.requestUrl = url;
            xhr.requestHref = document.location.href;
            originOpen.apply(xhr, args);
        };
        var originSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.send = function (body) {
            var args = [].slice.call(arguments);
            var xhr = this;
            var request = {
                requestId: xhr.requestId,
                requestHref: xhr.requestHref,
                requestUrl: xhr.requestUrl,
                bodyType: "String",
                value: null
            };
            if (!KKJSBridgeConfig.ajaxHook) { // 如果没有开启 ajax hook，则调用原始 send
                return originSend.apply(xhr, args);
            }
            if (!body) { // 没有 body，调用原始 send
                return originSend.apply(xhr, args);
            }
            else if (body instanceof ArrayBuffer) { // 说明是 ArrayBuffer，转成 base64
                request.bodyType = "ArrayBuffer";
                request.value = KKJSBridgeUtil.convertArrayBufferToBase64(body);
            }
            else if (body instanceof Blob) { // 说明是 Blob，转成 base64
                request.bodyType = "Blob";
                var fileReader = new FileReader();
                fileReader.onload = function (ev) {
                    var base64 = ev.target.result;
                    request.value = base64;
                    _XHR.sendBodyToNativeForCache(xhr, originSend, args, request);
                };
                fileReader.readAsDataURL(body);
                return;
            }
            else if (body instanceof FormData) { // 说明是表单
                request.bodyType = "FormData";
                KKJSBridgeUtil.convertFormDataToJson(body, function (json) {
                    request.value = json;
                    _XHR.sendBodyToNativeForCache(xhr, originSend, args, request);
                });
                return;
            }
            else { // 说明是字符串或者json
                request.bodyType = "String";
                request.value = body;
            }
            // 发送到 native 缓存起来
            _XHR.sendBodyToNativeForCache(xhr, originSend, args, request);
        };
        /**
         * hook form submit 方法
         */
        var originSubmit = HTMLFormElement.prototype.submit;
        HTMLFormElement.prototype.submit = function () {
            var args = [].slice.call(arguments);
            var form = this;
            form.requestId = _XHR.generateXHRRequestId();
            form.requestUrl = form.action;
            form.requestHref = document.location.href;
            var request = {
                requestId: form.requestId,
                requestHref: form.requestHref,
                requestUrl: form.requestUrl,
                bodyType: "FormData",
                value: null
            };
            if (!KKJSBridgeConfig.ajaxHook) { // 如果没有开启 ajax hook，则调用原始 submit
                return originSubmit.apply(form, args);
            }
            var action = form.action;
            if (!action) { // 如果 action 本身是空，则调用原始 submit
                return originSubmit.apply(form, args);
            }
            var formData = new FormData(form);
            KKJSBridgeUtil.convertFormDataToJson(formData, function (json) {
                request.value = json;
                _XHR.sendBodyToNativeForCache(form, originSubmit, args, request);
            });
        };
        /**
         * KKJSBridge 配置
         */
        var KKJSBridgeConfig = /** @class */ (function () {
            function KKJSBridgeConfig() {
            }
            KKJSBridgeConfig.ajaxHook = false;
            KKJSBridgeConfig.init = function () {
                window.KKJSBridge = KKJSBridgeInstance; // 设置新的 JSBridge 作为全局对象
            };
            /**
             * 开启 ajax hook
             */
            KKJSBridgeConfig.enableAjaxHook = function (enable) {
                if (enable) {
                    KKJSBridgeConfig.ajaxHook = true;
                    enableFetchHook(true);
                }
                else {
                    enableFetchHook(false);
                    KKJSBridgeConfig.ajaxHook = false;
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
        window.KKJSBridgeConfig.bridgeReady();
    };
    init();
    var index = window.KKJSBridge;

    return index;

})));
