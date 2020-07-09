/*
 * @Author: your name
 * @Date: 2020-07-07 13:08:18
 * @LastEditTime: 2020-07-09 16:44:45
 * @LastEditors: your name
 * @Description: In User Settings Edit
 * @FilePath: /TS/rollup.config.js
 */ 
import typescript from '@rollup/plugin-typescript';

// npm install && npm install --global rollup && npm run build

export default {
    input: 'src/index.ts',
    plugins: [typescript()],
    output: {
        file: 'dist/KKJSBridgeAJAXProtocolHook.js',
        format: 'umd',
        name: "KKJSBridge",
        amd: {
            id: 'lib/fetch.js',
            name: "KKFetch",
        }
    }
};