/*
 * @Author: your name
 * @Date: 2020-10-21 17:50:21
 * @LastEditTime: 2020-11-17 17:30:54
 * @LastEditors: Please set LastEditors
 * @Description: In User Settings Edit
 * @FilePath: /TS/src/global.d.ts
 */
interface Window {
    [name: string]: any;// window 下不做校验
    XMLHttpRequest: any;
}

interface XMLHttpRequest {
    requestId: string,
    requestUrl: string,
    requestHref: string
    requestMethod: string
    requestAsync: boolean
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