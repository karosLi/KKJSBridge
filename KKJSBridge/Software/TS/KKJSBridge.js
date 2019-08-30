;
(function (window) {
    ;
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
                var eventCallback = this.eventCallbackCache[callbackMessage.eventName];
                if (eventCallback) {
                    eventCallback(callbackMessage.data);
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
            this.eventCallbackCache[eventName] = callback;
        };
        return KKJSBridge;
    }());
    // 初始化 KKJSBridge
    var KKJSBridgeInstance = new KKJSBridge();
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
                    }
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
                if (xhr.callbackProperties.readyState === xhr.DONE && xhr.onload) {
                    xhr.onload();
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
                    function str2ArrayBuffer(str) {
                        var buf = new ArrayBuffer(str.length * 2); // 2 bytes for each char
                        var bufView = new Uint16Array(buf);
                        for (var i = 0, strLen = str.length; i < strLen; i++) {
                            bufView[i] = str.charCodeAt(i);
                        }
                        return buf;
                    }
                    // 懒加载返回 response array buffer
                    return str2ArrayBuffer(xhr.callbackProperties.responseText);
                }
            },
            //拦截回调
            onreadystatechange: function (xhr) {
                if (xhr.readyState === xhr.DONE) {
                    console.log("onreadystatechange called: %O", xhr);
                }
            },
            onload: function (xhr) {
                console.log("onload called: %O", xhr);
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
                    "async": async
                });
                return true;
            },
            send: function (arg, xhr) {
                console.log("send called:", arg[0]);
                var data = arg[0];
                if (data) {
                    // 特殊处理字节数据
                    var isByteData = false;
                    if (data instanceof Uint8Array) {
                        data = Array.from(data);
                        isByteData = true;
                    }
                    window.KKJSBridge.call(_XHR.moduleName, 'send', {
                        "id": this.id,
                        "isByteData": isByteData,
                        "data": data
                    });
                }
                else {
                    window.KKJSBridge.call(_XHR.moduleName, 'send', {
                        "id": this.id
                    });
                }
                return true;
            },
            overrideMimeType: function (arg, xhr) {
                console.log("overrideMimeType called:", arg[0]);
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
                console.log("setRequestHeader called:", arg[0], arg[1]);
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
                console.log("getAllResponseHeaders called");
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
            }
        });
    }
    function unHookAjax() {
        window._hookAjaxProxy.unHookAjax();
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
                            console.log('getCookie');
                            return cookieDesc.get.call(document);
                        },
                        set: function (val) {
                            console.log('setCookie');
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
        // 静态属性和方法
        KKJSBridgeConfig.moduleName = 'bridgeConfig';
        KKJSBridgeConfig.init = function () {
            window.KKJSBridge = KKJSBridgeInstance; // 设置新的 JSBridge 作为全局对象
        };
        KKJSBridgeConfig.loadConfigFromNative = function () {
            window.KKJSBridge.call(KKJSBridgeConfig.moduleName, 'fetchConfig', {}, function (data) {
                var isAjaxHook = data["isEnableAjaxHook"];
                // 如果是来自 native 侧自己的设置，则不需要再次通知 native 侧已经修改了 ajax hook 的值
                KKJSBridgeConfig.enableAjaxHookWithNotify(isAjaxHook, false);
            });
        };
        /**
         * 开启 ajax hook，方便 H5 自己控制是否开启 ajax hook
         */
        KKJSBridgeConfig.enableAjaxHook = function (enable) {
            KKJSBridgeConfig.enableAjaxHookWithNotify(enable, true);
        };
        /**
         * 开启 ajax hook 并 通知 native，方便 H5 自己控制是否开启 ajax hook
         */
        KKJSBridgeConfig.enableAjaxHookWithNotify = function (enable, notifyNative) {
            function _innerEnableAjaxHook(enable) {
                if (enable) {
                    hookAjax();
                }
                else {
                    unHookAjax();
                }
            }
            if (notifyNative) { // 是否需要通知到 native 侧，当需要通知 native 侧时，需要在通知后再来执行 H5 侧的开关修改
                window.KKJSBridge.call(KKJSBridgeConfig.moduleName, 'receiveConfig', { isEnableAjaxHook: enable }, function (data) {
                    console.log("h5 control ajaxHook ", enable);
                    _innerEnableAjaxHook(enable);
                });
            }
            else {
                console.log("native control ajaxHook ", enable);
                _innerEnableAjaxHook(enable);
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
    window.KKJSBridgeConfig.loadConfigFromNative(); // 加载 native 上的配置
    // window.KKJSBridgeConfig.enableAjaxHook(true); // 默认不开启 ajax hook
    window.KKJSBridgeConfig.bridgeReady();
})(window);
