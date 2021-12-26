import {_KKJSBridgeXHR} from './KKJSBridgeAjaxProtocolHook';

export class _KKJSBridgeSendBeaconHook {
    public static setupHook() {
        if (typeof window.navigator.sendBeacon === 'function') {
            const originalBeaconImpl = window.navigator.sendBeacon;
            window.navigator.sendBeacon = function (url: string, data?: BodyInit): boolean {
                if (!data) {
                    return originalBeaconImpl(url, data);
                }

                const requestId = _KKJSBridgeXHR.generateXHRRequestId();
                const requestUrl = _KKJSBridgeXHR.generateNewUrlWithRequestId(url, requestId);
                const requestRaw: KK.AJAXBodyCacheRequest = {
                    requestId: requestId,
                    requestHref: location.href,
                    requestUrl: url,
                    bodyType: 'String',
                    value: null
                };

                _KKJSBridgeXHR.resolveRequestBody(data).then(request => {
                    _KKJSBridgeXHR.sendBodyToNativeForCache('AJAX', window.navigator, originalBeaconImpl, [requestUrl, data], {
                        ...requestRaw,
                        ...request
                    });
                });

                return true;
            };
        }
    }
}
