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