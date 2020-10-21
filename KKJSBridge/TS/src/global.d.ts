interface Window {
    [name: string]: any;// window 下不做校验
    XMLHttpRequest: any;
}

interface XMLHttpRequest {
    requestId: string,
    requestUrl: string,
    requestHref: string
    requestMethod: string
}

interface HTMLFormElement {
    requestId: string,
    requestUrl: string,
    requestHref: string
}

interface ArrayConstructor {
    from<T, U>(arrayLike: ArrayLike<T>, mapfn: (v: T, k: number) => U, thisArg?: any): Array<U>;
    from<T>(arrayLike: ArrayLike<T>): Array<T>;
}