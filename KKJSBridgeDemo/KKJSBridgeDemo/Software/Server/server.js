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
        console.log('--------------------------------------------');
        console.log('RESPONSE', req.url, res.getHeaders());
        console.log('============================================');
    });

    /// 主入口
    if (req.url === '/index') {
        fs.readFile(path.join(__dirname,'index.html'),function (err,data) {
            if (err) {
                throw err;
            }
            res.setHeader('status', '200 OK');
            res.end(data)
        })
    } 
    /// 服务器端重定向
    else if (req.url === '/ajaxIndex302') {
        // 通过响应头来实现服务端重定向
        res.writeHead(302,{
            'Location': 'http://' + req.headers.host + '/ajaxIndex'
        })
        
        res.end();
    } 
    /// 模块测试相关
    else if (req.url === '/jsbridgeTest') {
        fs.readFile(path.join(__dirname,'jsbridgeTest.html'),function (err,data) {
            if (err) {
                throw err;
            }
            res.end(data)
        })
    }
    /// ajax 相关
    else if (req.url === '/ajaxIndex') {// ajax 主页
        fs.readFile(path.join(__dirname,'ajaxIndex.html'),function (err,data) {
            if (err) {
                throw err;
            }
            res.setHeader('status', '200 OK');
            res.end(data)
        })
    } 
    
    else if (req.url === '/ajaxHookTest') {// ajax hook 主页
        fs.readFile(path.join(__dirname,'ajaxHookTest.html'),function (err,data) {
            if (err) {
                throw err;
            }
            res.setHeader('status', '200 OK');
            res.setHeader('Set-Cookie', ['test_token1=1;', 'test_token2=2;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;', 'test_token3=3;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;HTTPOnly;']);
            res.end(data)
        })
    }  
    else if (req.url === '/ajaxiframeTest') {// ajax iframe
        fs.readFile(path.join(__dirname,'ajaxiframeTest.html'),function (err,data) {
            if (err) {
                throw err;
            }
            res.end(data)
        })
    } else if (req.url === '/client302') {// ajax - 重定向
        fs.readFile(path.join(__dirname,'client302.html'),function (err,data) {
            if (err) {
                throw err;
            }
            res.end(data)
        })
    } else if (req.url === '/testAjaxGet') {// ajax hook - get
        res.setHeader('status', '200 OK');
        res.setHeader('Content-Type', 'text/plain');
        res.setHeader('Set-Cookie', ['get_ajax_token=55;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;HTTPOnly;', 'get_ajax_token1=66;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;']);
        res.end('testAjaxGet');
    } else if (req.url === '/testAjaxPost') {// ajax hook - post
        res.setHeader('status', '200 OK');
        res.setHeader('Content-Type', 'text/plain');
        res.setHeader('Set-Cookie', ['post_ajax_token=55;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;HTTPOnly;', 'post_ajax_token1=66;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;']);
        
        let body = '';
        req.on('data', chunk => {
            body += chunk.toString(); // convert Buffer to string
        });
        req.on('end', () => {
            console.log(body);
            setTimeout(function() {
              res.end('testAjaxPost ' + body);
            }, 1000);
        });
        
    } else if (req.url === '/testAjaxGetHtml') {// ajax hook - get html
        res.setHeader('status', '200 OK');
        res.setHeader('Content-Type', 'text/html');
        res.end('<input name="q" value="test">');
    }
    else if (req.url === '/ajaxFormData') {// ajax 表单主页
        fs.readFile(path.join(__dirname,'ajaxFormData.html'),function (err,data) {
            if (err) {
                throw err;
            }
            res.end(data)
        })
    } 
    else if (req.url === '/relative/ajax/index') {// ajax 相对路径主页
        fs.readFile(path.join(__dirname,'ajaxRelativeTest'),function (err,data) {
            if (err) {
                throw err;
            }
            res.setHeader('status', '200 OK');
            res.setHeader('Set-Cookie', ['test_token1=1;', 'test_token2=2;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;', 'test_token3=3;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;HTTPOnly;']);
            res.end(data)
        })
    } 
    else if (req.url === '/relative/ajax/testAjaxPostWithRelative1') {
        res.setHeader('status', '200 OK');
        res.setHeader('Content-Type', 'text/plain');
        res.end('ajax 相对路径[./]');
    } else if (req.url === '/relative/testAjaxPostWithRelative2') {
        res.setHeader('status', '200 OK');
        res.setHeader('Content-Type', 'text/plain');
        res.end('ajax 相对路径[../]');
    } else if (req.url === '/testAjaxPostWithRelative3') {
        res.setHeader('status', '200 OK');
        res.setHeader('Content-Type', 'text/plain');
        res.end('ajax 相对路径[../../]');
    } else if (req.url === '/testAjaxPostWithAbsolute') {
        res.setHeader('status', '200 OK');
        res.setHeader('Content-Type', 'text/plain');
        res.end('ajax 绝对路径[/]');
    } 
    /// fetch 相关
    else if (req.url === '/fetchIndex') {// fetch 主页
        fs.readFile(path.join(__dirname,'fetchIndex.html'),function (err,data) {
            if (err) {
                throw err;
            }
            res.setHeader('status', '200 OK');
            res.end(data)
        })
    } 
    else if (req.url === '/fetchHookTest') { // fetch hook 主页
        fs.readFile(path.join(__dirname,'fetchHookTest.html'),function (err,data) {
            if (err) {
                throw err;
            }
            res.end(data)
        })
    } else if (req.url === '/fetch.umd.js') {
        fs.readFile(path.join(__dirname,'fetch.umd.js'),function (err,data) {
            if (err) {
                throw err;
            }
            res.end(data)
        })
    }  else if (req.url === '/testFetchGet') {// fetch hook - get
        res.setHeader('status', '200 OK');
        res.setHeader('Content-Type', 'text/plain');
        res.setHeader('Set-Cookie', ['get_ajax_token=55;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;HTTPOnly;', 'get_ajax_token1=66;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;']);
        res.end('testFetchGet');
    } else if (req.url === '/testFetchPost') {// fetch hook - post
        res.setHeader('status', '200 OK');
        res.setHeader('Content-Type', 'text/plain');
        res.setHeader('Set-Cookie', ['post_ajax_token=55;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;HTTPOnly;', 'post_ajax_token1=66;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;']);
        
        let body = '';
        req.on('data', chunk => {
            body += chunk.toString(); // convert Buffer to string
        });
        req.on('end', () => {
            console.log(body);
            res.end('testFetchPost ' + body);
        });
    } else if (req.url === '/testFetchGetHtml') {// fetch hook - get html
        res.setHeader('status', '200 OK');
        res.setHeader('Content-Type', 'text/html');
        res.end('<input name="q" value="test">');
    }
    else if (req.url === '/fetchFormData') {// fetch 表单主页
        fs.readFile(path.join(__dirname,'fetchFormData.html'),function (err,data) {
            if (err) {
                throw err;
            }
            res.end(data)
        })
    } 
    else if (req.url === '/relative/fetch/index') {// fetch 相对路径主页
        fs.readFile(path.join(__dirname,'fetchRelativeTest'),function (err,data) {
            if (err) {
                throw err;
            }
            res.setHeader('status', '200 OK');
            res.setHeader('Set-Cookie', ['test_token1=1;', 'test_token2=2;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;', 'test_token3=3;domain='+srvUrl.hostname+';path=/;expires=Mon, 01 Aug 2050 06:44:35 GMT;HTTPOnly;']);
            res.end(data)
        })
    } 
    else if (req.url === '/relative/fetch/testFetchPostWithRelative1') {
        res.setHeader('status', '200 OK');
        res.setHeader('Content-Type', 'text/plain');
        res.end('fetch 相对路径[./]');
    } else if (req.url === '/relative/testFetchPostWithRelative2') {
        res.setHeader('status', '200 OK');
        res.setHeader('Content-Type', 'text/plain');
        res.end('fetch 相对路径[../]');
    } else if (req.url === '/testFetchPostWithRelative3') {
        res.setHeader('status', '200 OK');
        res.setHeader('Content-Type', 'text/plain');
        res.end('fetch 相对路径[../../]');
    } else if (req.url === '/testFetchPostWithAbsolute') {
        res.setHeader('status', '200 OK');
        res.setHeader('Content-Type', 'text/plain');
        res.end('fetch 绝对路径[/]');
    } 
})

// 6. 启用服务器
server.listen(50000,function () {
    console.log('启用成功'); 
    console.log('test for 200 http://127.0.0.1:50000/index');
})
