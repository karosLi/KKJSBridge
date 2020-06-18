/*
 * @Author: your name
 * @Date: 2020-06-18 14:07:12
 * @LastEditTime: 2020-06-18 14:49:50
 * @LastEditors: Please set LastEditors
 * @Description: In User Settings Edit
 * @FilePath: /TS/util/qtoken.js
 */ 

 // https://developer.qiniu.com/kodo/sdk/1289/nodejs
 // npm install && npm run qtoken

var qiniu = require('qiniu');
var accessKey = 'RSxpQIxNIS2vo0vuQR3HX701ddS9fdlUnQ5jV8u1';
var secretKey = 'xCLWczC5V5kyy7H85MNKNYcXT4wx9k5OzT7YDVFa';
var mac = new qiniu.auth.digest.Mac(accessKey, secretKey);
var options = {
    scope: 'karospics',
    expires: 10*365*24*7200
};

var putPolicy = new qiniu.rs.PutPolicy(options);
var uploadToken = putPolicy.uploadToken(mac);
console.log(uploadToken);





