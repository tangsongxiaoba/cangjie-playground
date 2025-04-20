package playground

import std.io.StringReader
import std.time.Duration
import encoding.json.*
import net.http.*
import net.tls.*

enum Role <: ToString {
    I | AI | System
    public func toString() {
        match (this) {
            case I => 'user'
            case AI => 'assistant'
            case System => 'system'
        }
    }
}

class LLM {
    let client: Client
    let prompt = 'I am going to give you a block of code. If the block of code is a function, you need to tell me the meanings of the parameters that the function contains, the actions that the function can do, and the return value of the function. If the block of code is a class, you need to tell me the superclass that the class inherits from, the interface that the class inherits from, the properties that the class contains, and a description of the methods that the class contains. Requirements: Your answer must be as short as possible, with newline characters separating each point and no additional content allowed.'
    let history = StringBuilder()
    public LLM(let url!: String, let key!: String, let model!: String,
        let context!: Bool = false) {
        var config = TlsClientConfig()
        config.verifyMode = TrustAll
        client = ClientBuilder()
            .tlsConfig(config)
            .readTimeout(Duration.Max) // AI 服务响应有时候比较慢，这里设置为无限等待
            .build()
        history.append(encode(I, prompt) + ',')
    }

    func encode(role: Role, content: String) {
        '{"role":"${role}","content":${JsonString(content)}}'
    }

    func send(input: String, stream!: Bool = false) {
        let message = encode(I, input)
        let content =
            '{"model":"${model}","messages":[${history}${message}],"stream":${stream}}'
        if (context) { history.append(message) }
        let request = HttpRequestBuilder()
            .url(url)
            .header('Authorization', 'Bearer ${key}')
            .header('Content-Type', 'application/json;charset=utf-8')
            .header('Accept', if (stream) {
                'text/event-stream'
            } else {
                'application/json'
            })
            .body(content)
            .post()
            .build()
        client.send(request)
    }

    func parse(text: String, stream!: Bool = false) {
        let json = JsonValue.fromStr(text).asObject()
        let choices = json.getFields()['choices'].asArray()
        // 流式和非流式情况下，这个字段名称不同
        let key = if (stream) { 'delta' } else { 'message' }
        let message = choices[0].asObject().getFields()[key].asObject()
        let content = message.getFields()['content'].asString().getValue()
        return content
    }

    // 非流式
    public func chat(input: String) {
        println("chating...")
        let response = send(input)
        let output = StringReader(response.body).readToEnd() |> parse
        return output
    }

    public func reset() {
        history.reset()
    }
}