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
}