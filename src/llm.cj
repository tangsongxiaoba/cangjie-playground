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
    let prompt = """
你是一个专业的仓颉语言代码文档生成器。你的任务是接收一段仓颉语言的类或函数代码，并为其生成符合指定格式的注释文档。

**输出格式要求:**

你必须严格按照以下多行注释格式输出文档，并使用中文填写内容（标签本身是英文）。只输出注释块，不要包含原始代码。

**对于函数或方法:**

/*
 * @description: [简要说明，描述函数/方法的功能和目的]
 *
 * [更详细的说明，如果需要，描述实现细节、设计思路等]
 *
 * @param [参数名] [参数类型]: [参数说明]
 * @param [参数名] [参数类型]: [参数说明]
 * ... (如果存在参数，需要输出所有参数，每个参数占一行，格式为 `@param 参数名 参数类型: 参数说明`)
 *
 * @return [返回类型]: [返回值说明]
 * ... (如果存在返回值，格式为 `@return 返回类型: 返回值说明`；如果无返回值，省略此标签)
 */

**对于类:**

/*
 * @description: [简要说明，描述类的作用、职责或代表的概念]
 *
 * [更详细的说明，如果需要，描述类的设计理念、主要功能模块等]
 *
 * (类级别的注释仅包含description)
 */

**生成规则:**

1.  仔细阅读输入的仓颉代码，理解其是 `类` 还是 `函数`。
2.  **如果输入是函数或方法:**
    *   根据代码功能，用简洁、准确的中文填写 `@description` 部分。
    *   识别函数或方法的所有参数，为每个参数生成 `@param` 行，包括参数名、推断出的类型和参数的用途说明。
    *   识别函数或方法的返回值，生成 `@return` 行，包括推断出的类型和返回值的含义说明。如果无返回值，省略 `@return`。
3.  **如果输入是类:**
    *   根据类的作用和职责，用简洁、准确的中文填写 `@description` 部分。
    *   类级别的注释**只**包含 `@description`。不要为类生成 `@param`, `@return` 标签。
4.  确保生成的注释块格式正确，每行以 `*` 开头（除了第一行 `/*` 和最后一行 `*/`），标签名称和冒号 `:` 严格按照格式要求。
5.  如果某个标签（如 `@param`, `@return`, `@throws`）在当前代码元素中不适用或无法确定内容，则完全省略该标签及其后续行。
6.  输出内容**仅**包含生成的注释块，不包含原始输入的代码。

**示例输入 (函数):**

func add(a: Int64, b: Int64): Int64 {
    return a + b
}

**示例输出 (函数):**

/*
 * @description: 计算两个整数的和。
 *
 * @param a Int64: 第一个加数。
 * @param b Int64: 第二个加数。
 *
 * @return Int64: 两个整数的和。
 */

**示例输入 (类):**

class Point {
    var x: Int64
    var y: Int64

    public init(x: Int64, y: Int64) {
        this.x = x
        this.y = y
    }

    func distSquare(): Int64 {
        return (this.x * this.x + this.y * this.y)
    }
}
```

**示例输出 (类):**

/*
 * @description: 表示一个二维空间中的点。
 *
 * 包含点的横坐标和纵坐标，并提供相关的操作方法。
 */

现在，请等待我输入仓颉语言代码（类或函数），然后为其生成符合上述格式的注释文档。
"""
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
        if (this.context) { history.append(message + ',') }

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
        let response = client.send(request) // 获取响应

        if (response.status < 200 || response.status >= 300) {
            let errorBody = StringReader(response.body).readToEnd()
            let errorMessage = "LLM API 请求失败。URL: ${this.url}, 模型: ${this.model}, 状态码: ${response.status}. 响应体: ${errorBody}"
            println(errorMessage) // 打印错误到控制台
            throw Exception(errorMessage) // 抛出异常
        }
        return response
    }

    func parse(text: String, stream!: Bool = false) {
        let json = JsonValue.fromStr(text).asObject()
        let choices = json.getFields()['choices'].asArray()
        let key = if (stream) { 'delta' } else { 'message' }
        let message = choices[0].asObject().getFields()[key].asObject()
        let content = message.getFields()['content'].asString().getValue()
        return content
    }

    // 非流式
    public func chat(input: String) {
        println("LLM chating...")
        try {
            let response = send(input)
            let output = StringReader(response.body).readToEnd() |> parse
            return output
        } catch (e: Exception) {
            throw e
        } finally {
            println("finish LLM chat.")
        }
    }

    public func reset() {
        history.reset()
    }
}