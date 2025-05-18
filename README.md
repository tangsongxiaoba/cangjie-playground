# 仓颉操场

对仓颉语言程序进行分析、重构等操作的代码工具。

## 使用方法

在 Linux 上安装0.53.18版本仓颉工具链（见[文档](https://cangjie-lang.cn/docs?url=%2F0.53.18%2Fuser_manual%2Fsource_zh_cn%2Ffirst_understanding%2Finstall_Community.html)）。然后运行 `cjpm run`。

搭配[前端](https://github.com/tangsongxiaoba/cangjie-playground-ui)使用。

## API 接口

- baseUrl: http://<ip>:<port>/api/cj-tool

1. generateCodeSignature
   - path: /generate-signature
   - method: POST
   - data: { "code": "string"}
   - response: { "success": true, "data": { "signature": "string" } }
2. refactorVariable
   - path: /refactor-variable
   - method: POST
   - data: { "code": "string", "path": "string", "oldName": "string", "newName": "string"}
   - response: { "success": true, "data": { "refactoredCode": "string" } }
3. generateDocument
   - path: /generate-document
   - method: POST
   - data: { "code": "string", "path": "string", "apiKey": "string", "apiUrl": "string", "modelName": "string"}
   - response: { "success": true, "data": { "documentedCode": "string" } }
4. foldConstant
   - path: /fold-constant
   - method: POST
   - data: { "code": "string"}
   - response: { "success": true, "data": { "foldedCode": "string" } }
5. findUnusedVariables
   - path: /find-unused-variables
   - method: POST
   - data: { "code": "string"}
   - response: { "success": true, "data": { "modifiedCode": "string" } }