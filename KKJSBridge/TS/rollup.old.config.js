/*
 * @Author: your name
 * @Date: 2020-07-06 18:25:49
 * @LastEditTime: 2020-07-06 18:26:22
 * @LastEditors: your name
 * @Description: In User Settings Edit
 * @FilePath: /TS/rollup.old.config.js
 */ 
import typescript from '@rollup/plugin-typescript';

// npm install && npm install --global rollup && npm run build

export default {
    input: 'src/indexold.ts',
    plugins: [typescript()],
    output: {
        file: 'dist/KKJSBridgeOld.js',
        format: 'umd',
        name: "KKJSBridge",
        amd: {
            id: 'lib/fetch.js',
            name: "KKFetch",
        }
    }
};