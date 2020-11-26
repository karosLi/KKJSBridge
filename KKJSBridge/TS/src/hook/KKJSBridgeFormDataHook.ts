export class _KKJSBridgeFormData {
	/**
	 * Hook FormData，由于低版本的 FormData 没有支持 entries() 等遍历 api，所以只是在 ajax send 里遍历，是无法获取到具体的值的，
	 * 所以针对低版本的 iOS 系统做 Hook FormData 处理。
	 */
	public static setupHook: Function = () => {
    var originAppend = window.FormData.prototype['append'];
    var originEntries = window.FormData.prototype['entries'];
    if (!originEntries) {
      window.FormData.prototype['append'] = function() {
        if (!this._entries) {
          this._entries = [];
        }
        this._entries.push(arguments);
        return originAppend.apply(this, arguments);
      }
    }
  }
  
  /**
   * 遍历表单记录
   */
  public static traversalEntries: Function = (formData: any, traversal?: (key: string, value: any, fileName?: string) => void) => {
    if (formData._entries) { // 低版本的 iOS 系统，并不支持 entries() 方法，所以这里做兼容处理
      for (let i = 0; i < formData._entries.length; i++) {
        let pair = formData._entries[i];
        let key: string = pair[0];
        let value: any = pair[1];
        let fileName = pair.length > 2 ? pair[2] : null;
      
        if (traversal) {
          traversal(key, value, fileName);
        }
      }
    } else {
      // JS 里 FormData 表单实际上也是一个键值对
      for(let pair of formData.entries()) {
        let key: string = pair[0];
        let value: any = pair[1];

        if (traversal) {
          traversal(key, value, null);
        }
      }
    }
  }
}