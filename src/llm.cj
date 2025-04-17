// 本示例演示访问 DeepSeek 大模型
// 仓颉语言团队 刘俊杰 2025.02.05
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
    let prompt = "Based on the body of the function I gave you, generate a paragraph explaining what the function does. The text must not contain newline characters."
    let history = StringBuilder()
    public LLM(let url!: String, let key!: String, let model!: String,
        let context!: Bool = false) {
        var config = TlsClientConfig()
        config.verifyMode = TrustAll
        client = ClientBuilder()
            .tlsConfig(config)
            .readTimeout(Duration.Max) // AI 服务响应有时候比较慢，这里设置为无限等待
            .build()
        history.append(encode(I, prompt))
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
        println("text: ${text}")
        let json = JsonValue.fromStr(text).asObject()
        let choices = json.getFields()['choices'].asArray()
        println("choices: ${choices}")
        // 流式和非流式情况下，这个字段名称不同
        let key = if (stream) { 'delta' } else { 'message' }
        let message = choices[0].asObject().getFields()[key].asObject()
        let content = message.getFields()['content'].asString().getValue()
        return content
    }

    // 非流式
    public func chat(input: String) {
        let response = send(input)
        let buffer = Array<Byte>(4096 * 8, item: 0)
        response.body.read(buffer)
        let output = StringReader(response.body).readToEnd() |> parse
        println(output)
        return output
    }

    // public func preset(context: Array<(Role, String)>) {
    //     history.reset()
    //     for ((role, message) in context) {
    //         history.append(encode(role, message) + ',')
    //     }
    // }

    public func reset() {
        history.reset()
    }
}