/*
 * @Author: your name
 * @Date: 2020-07-06 18:25:49
 * @LastEditTime: 2020-10-21 18:04:39
 * @LastEditors: Please set LastEditors
 * @Description: In User Settings Edit
 * @FilePath: /TS/rollup.old.config.js
 */ 
import typescript from '@rollup/plugin-typescript';

// npm install && npm install --global rollup && npm run buildold

export default {
    input: 'src/indexold.ts',
    plugins: [typescript()],
    output: {
        file: 'dist/KKJSBridgeAJAXHook.js',
        format: 'umd',
        name: "KKJSBridge",
        amd: {
            id: 'lib/fetch.js',
            name: "KKFetch",
        }
    }
};