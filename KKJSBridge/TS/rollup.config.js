import typescript from '@rollup/plugin-typescript';

// npm install && npm install --global rollup && npm run build

export default {
    input: 'src/indexold.ts',
    plugins: [typescript()],
    output: {
        file: 'dist/KKJSBridge.js',
        format: 'umd',
        name: "KKJSBridge",
        amd: {
            id: 'lib/fetch.js',
            name: "KKFetch",
        }
    }
};