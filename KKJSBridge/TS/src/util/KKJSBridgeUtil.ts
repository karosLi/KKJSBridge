/// <reference path="../../types/index.d.ts" />

/**
 * KKJSBridge 工具
 */
export class KKJSBridgeUtil {
    
	/**
	 * 把 arraybuffer 转成 base64
	 * @param arraybuffer 
	 */
	public static convertArrayBufferToBase64(arraybuffer: ArrayBuffer) {
		let uint8Array: Uint8Array = new Uint8Array(arraybuffer);
		let charCode: string = "";
		let length = uint8Array.byteLength;
		for (let i = 0; i < length; i++) {
			charCode += String.fromCharCode(uint8Array[i]);
		}
		// 字符串转成base64
		return window.btoa(charCode);
	}

	/**
	 * 转换 form 表单到 json 对象
	 * @param formData 
	 * @param callback 
	 */
	public static convertFormDataToJson(formData: any, callback: (json: any) => void) {
		let allPromise: Array<Promise<Array<any>>> = [];
		if (formData._entries) { // 低版本的 iOS 系统，并不支持 entries() 方法，所以这里做兼容处理
			for (let i = 0; i < formData._entries.length; i++) {
				let pair = formData._entries[i];
				let key: string = pair[0];
				let value: any = pair[1];
				let fileName = pair.length > 2 ? pair[2] : null;
				allPromise.push(KKJSBridgeUtil.convertSingleFormDataRecordToArray(key, value, fileName));
			}
		} else {
			// JS 里 FormData 表单实际上也是一个键值对
			for(let pair of formData.entries()) {
				let key: string = pair[0];
				let value: any = pair[1];
				allPromise.push(KKJSBridgeUtil.convertSingleFormDataRecordToArray(key, value));
			}
		}
		
		Promise.all(allPromise).then((formDatas: Array<Array<any>>) => {
			let formDataJson: any = {};
			let formDataFileKeys = [];
			for(let i = 0; i < formDatas.length; i++) {
				let singleKeyValue: Array<any> = formDatas[i];
				// 只要不是字符串，那就是一个类文件对象，需要加入到 formDataFileKeys 里，方便 native 做编码转换
				if (singleKeyValue.length > 1 && !(typeof singleKeyValue[1] == "string")) {
				formDataFileKeys.push(singleKeyValue[0]);
				}
			}
			formDataJson['fileKeys'] = formDataFileKeys;
			formDataJson['formData'] = formDatas;
			callback(formDataJson);
		}).catch(function (error: Error) {
			console.log(error);
		});
	}

	/**
	 * 转换表单单条记录到一个数组对象
	 * @param key 
	 * @param value 
	 * @param fileName 
	 */
	public static convertSingleFormDataRecordToArray(key: string, value: any, fileName?: string): Promise<Array<any>> {
		return new Promise<Array<any>>((resolve, reject) => {
			let singleKeyValue: Array<any> = [];
			singleKeyValue.push(key);
			if (value instanceof File || value instanceof Blob) { // 针对文件特殊处理
				let reader: FileReader = new FileReader();
				reader.readAsDataURL(value);
				reader.onload = function(this: FileReader, ev: ProgressEvent) {
					let base64: string = (ev.target as any).result;
					let formDataFile: KK.FormDataFile = {
						name: fileName ? fileName : (value instanceof File ? (value as File).name : ''),
						lastModified: value instanceof File ? (value as File).lastModified : 0,
						size: value.size,
						type: value.type,
						data: base64
					};
					singleKeyValue.push(formDataFile);
					resolve(singleKeyValue);
					return null;
				};
				reader.onerror = function(this: FileReader, ev: ProgressEvent) {
					reject(Error("formdata 表单读取文件数据失败"));
					return null;
				};
			} else {
				singleKeyValue.push(value);
				resolve(singleKeyValue);
			}
		});
	}

	/**
	 * 读取单个文件数据，并转成 base64，最后返回 json 对象
	 * @param file 
	 */
	public static convertFileToJson(file: File | Blob): Promise<KK.FormDataFile> {
		return new Promise<KK.FormDataFile>((resolve, reject) => {
			let reader: FileReader = new FileReader();
			reader.readAsDataURL(file);
			reader.onload = function(this: FileReader, ev: ProgressEvent) {
				let base64: string = (ev.target as any).result;
				let formDataFile: KK.FormDataFile = {
					name: file instanceof File ? (file as File).name : '',
					lastModified: file instanceof File ? (file as File).lastModified : 0,
					size: file.size,
					type: file.type,
					data: base64
				};
				resolve(formDataFile);
				return null;
			};
			reader.onerror = function(this: FileReader, ev: ProgressEvent) {
				reject(Error("formdata 表单读取文件数据失败"));
				return null;
			};
		});
	}
}

/**
 * 处理 iframe 相关
 */
export class KKJSBridgeIframe {
  /**
   * 分发消息
   * @param messageString
   */
  public static dispatchMessage(messageString: string) {
    // 处理有 iframe 的情况
    let iframes : NodeListOf<HTMLIFrameElement> = document.querySelectorAll("iframe");
    if (iframes) {
      let len: number = iframes.length;
      for (let i = 0; i < len; i++) {
        let win: any = iframes[i].contentWindow;
        win.postMessage(messageString, '*');
      }
    }
  }

  /**
   * 添加消息监听处理
   */
  public static addMessageListener() {
    // iframe 内处理来自父 window 的消息
    window.addEventListener('message', e => {
      let data: any = e.data;
      if (typeof data == "string") {
        let str: string = data as string;
        if (str.indexOf("messageType") != -1) {
          window.KKJSBridge._handleMessageFromNative(str);
        }
      }
    });
	}
	
	/**
	 * 添加 ajax 消息监听处理
	 */
	public static addAjaxMessageListener() {
		// iframe 内处理来自父 window ajax 回调消息
		window.addEventListener('message', e => {
			let data: any = e.data;
			if (typeof data == "string") {
				let str: string = data as string;
				if (str.indexOf("ajaxType") != -1) {
					window._KKJSBridgeXHR.setProperties(str);
				}
			}
		});
	}

  /**
   * 让 iframe 能够注入 app 里面的脚本
   */
  public static setupHook() {
    // 设置 iframe 标签 的 sandbox 属性
    document.addEventListener('DOMContentLoaded',function(){
      let iframes : NodeListOf<HTMLIFrameElement> = document.querySelectorAll("iframe");
      if (iframes) {
        let len: number = iframes.length;
        for (let i = 0; i < len; i++) {
          let iframe: HTMLIFrameElement = iframes[i];
          if (iframe.getAttribute('sandbox') && iframe.getAttribute('sandbox').indexOf('allow-scripts') == -1) {
            iframe.setAttribute('sandbox', iframe.getAttribute('sandbox') + ' allow-scripts');
          }
        }
      }
    });

    // 设置 iframe 动态创建的 sandbox 属性
    let originalCreateElement = document.createElement;
    document.createElement = function (tag: string) {
      var element = originalCreateElement.call(document, tag);
      if (tag.toLowerCase() === 'iframe') {
        try {
          var iframeSandbox = Object.getOwnPropertyDescriptor(window.HTMLIFrameElement, 'sandbox') ||
                        Object.getOwnPropertyDescriptor(HTMLIFrameElement.prototype, 'sandbox');
          if (iframeSandbox && iframeSandbox.configurable) {
						Object.defineProperty(element, 'sandbox', {
							configurable: true,
							enumerable: true,
							get: function () {
								return iframeSandbox.get.call(element);
							},
							set: function (val) {
								if (val.indexOf('allow-scripts') == -1) {
									val = val + ' allow-scripts';
								}
								iframeSandbox.set.call(element, val);
							}
						});
          }
        } catch(e) {
          console.log('this browser does not support reconfigure iframe sandbox property', e);
        }
      }
      return element;
    };
  }
}