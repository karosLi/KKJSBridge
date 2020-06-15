// node server.js

// 1. 导入http模块
const http = require('http');
// 2. 导入文件模块
const fs = require('fs');
// 3. 导入路径模块
const path = require('path');
const url = require('url');
// 4. 创建服务器
const server = http.createServer();
// 5. 监听客户端请求
server.on('request', function (req,res) {
    console.log('============================================');
    console.log('REQUEST', req.url, req.headers);
    const srvUrl = url.parse(`http://${req.headers.host}`);
    // console.log('srvUrl', srvUrl);

    req.on('end', function() {
        console.log('============================================');
        console.log('RESPONSE', req.url, res.getHeaders());
    });

    if (req.url === '/index302') {
        // 通过响应头来实现服务端重定向
        res.writeHead(302,{
            'Location': 'http://' + req.headers.host + '/index'
        })
        
        res.end();
    } else if (req.url === '/index') {
        fs.readFile(path.join(__dirname,'index.html'),function (err,data) {
            if (err) {
                throw err;
            }
            res.setHeader('status', '200 OK');
            res.setHeader('Set-Cookie', ['test_token1=1;', 'test_token2=2;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;', 'test_token3=3;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;HTTPOnly;']);
            res.end(data)
        })
    } else if (req.url === '/client302') {
        fs.readFile(path.join(__dirname,'client302.html'),function (err,data) {
            if (err) {
                throw err;
            }
            res.end(data)
        })
     } else if (req.url === '/moduleTest') {
        fs.readFile(path.join(__dirname,'moduleTest.html'),function (err,data) {
            if (err) {
                throw err;
            }
            res.end(data)
        })
     } else if (req.url === '/testAjaxGet') {
        res.setHeader('status', '200 OK');
        res.setHeader('Content-Type', 'text/plain');
        res.setHeader('Set-Cookie', ['get_ajax_token=55;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;HTTPOnly;', 'get_ajax_token1=66;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;']);
        res.end('testAjaxGet');
    } else if (req.url === '/testAjaxPost') {
        res.setHeader('status', '200 OK');
        res.setHeader('Content-Type', 'text/plain');
        res.setHeader('Set-Cookie', ['post_ajax_token=55;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;HTTPOnly;', 'post_ajax_token1=66;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;']);
        res.end('testAjaxPost');
    } else if (req.url === '/testAjaxGetHtml') {
        fs.readFile(path.join(__dirname,'moduleTest.html'),function (err,data) {
            if (err) {
                throw err;
            }

            res.setHeader('status', '200 OK');
            res.setHeader('Content-Type', 'text/html');
            res.end(data)
        })
    } else if (req.url === '/formData') {
        fs.readFile(path.join(__dirname,'formData.html'),function (err,data) {
            if (err) {
                throw err;
            }
            res.end(data)
        })
     } 
})

// 6. 启用服务器
server.listen(50000,function () {
    console.log('启用成功'); 
    console.log('test for 200 http://127.0.0.1:50000/index');
    console.log('test for 302 http://127.0.0.1:50000/index302')
})
