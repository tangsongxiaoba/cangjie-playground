package playground

import std.ast.*
import std.fs.*

let code_1_1_1 = """
abstract interface ILogger {
    func log(message: String): Bool

    func performCalculation(operand1: Float64, operand2: Float64, operationType: String): Float64
    
    func utilityHelper(value: Int64, unusedParam: Bool): Unit
    
    func testRanges(): Unit
}

class AdvancedCalculator <: ILogger {
    public var lastResult: Float64 = 0.0
    private var calculationCount: Int64 = 0
    private var historyCapacity: Int64 = 100 * 2
    private var unusedProperty: String = "This is not used"

    public mut prop result: Int64 {
        get() {
            lastResult
        }
        set(result) {
            lastResult = result
        }
    }
    
    public func log(message: String): Bool {
        if(logLevel > 0) {
            return true
        }
        let unusedInLog: Int64 = 55
        return false
    }

    public func performCalculation(operand1: Float64, operand2: Float64, operationType: String): Float64 {
        var result: Float64 = 0.0
        let fixedBonus: Float64 = 1.0 + 0.5 * 2.0
        var unusedLocalInCalc: Bool = true
        
        if(operationType == "add") {
            result = operand1 + operand2 + fixedBonus
        } else if(operationType == "subtract") {
            result = operand1 - operand2 + fixedBonus
        } else if(operationType == "multiply") {
            let interimResult = operand1 * operand2
            result = interimResult *(10 / 4) + fixedBonus
        } else if(operationType == "divide") {
            if(operand2 != 0) {
                result = operand1 / operand2 + fixedBonus
            } else {
                result = 0.0
            }
        }
        
        return result
    }
    
    private func utilityHelper(value: Int64, unusedParam: Bool) {
        let localConstant =(2 + 3) * 4
        var tempVar = value + localConstant
        if(tempVar > 100) { }
    }
    
    func testRanges() {
        let r1 = 0 .. 10
        let r2 =(1 + 1) ..(5 * 2):(10 / 5)
        let r3 = 0 ..=(100 - 50)
        var unusedInRangeLoopVar = "test"
        
        for(i in r2) {
            let current = i
        }

        var test = 10
        for(j in 0..10+3){
            test = test + j
        }
    }
}

func formatGreeting(name: String, age: Int64): String {
    let baseGreeting = "Hello"
    let unusedGlobalFuncVar: Int64 = 1000
    if(age >(10 + 8)) {
        return "you are an adult of age"
    } else {
        return "you are young at age"
    }
}

class DataProcessor {
    var data: Array < Int64 >
    var processed: Bool = false
    
    public func processData() {
        for(item in data) {
            let tempItem = item *(1 + 1)
            tempItem += 1
        }
        processed = true
    }
}
"""

let code_1_1_2 = """
// 本示例演示访问 DeepSeek 大模型
class LLM {
let client: Client
let history = StringBuilder()
    func encode(role: Role, content: String) {        '{"role":"\${role}","content":\${JsonString(content)}}'
}
    func send(input: String, stream!: Bool = false) {
        let message = encode(I, input)
let content =
            '{"model":"\${model}","messages":[\${history}\${message}],"stream":\${stream}}'
if (context) { history.append(message) }
        let request = HttpRequestBuilder()
            .url(url)
            .header('Authorization', 'Bearer \${key}')
            .header('Content-Type', 'application/json')
            .header('Accept', if (stream) {
                'text/event-stream'
            } else {
                'application/json'
            })
            .body(content)
            .post()
            .build()
        client.send(request)}
    func parse(text: String, stream!: Bool = false) {
        let json = JsonValue.fromStr(text).asObject()
        let choices = json.getFields()['choices'].asArray()
// 流式和非流式情况下，这个字段名称不同
        let key = if (stream) { 'delta' } else { 'message' }
    let message = choices[0].asObject().getFields()[key].asObject()
      let content = message.getFields()['content'].asString().getValue()
  return content}
    // 流式对话
    public func chat(input: String, task!: (String) -> Unit = {o => print(o)}) {
        let response = send(input, stream: true)
 let output = StringBuilder()
   let buffer = Array<Byte>(1024*8,item:0)
   var length = response.body.read(buffer)
        while(length!=0) {
let text = String.fromUtf8(buffer[..length])
            const INDEX = 6
            for (line in text.split('\n', removeEmpty: true)) {
      if (line.size > INDEX && line[INDEX] == b'{') {
                    let json = line[INDEX..line.size]
                    let slice = parse(json, stream: true)
                    if (context) { output.append(slice) }
                    task(slice)
                }
            }
            length = response.body.read(buffer)
        }
        if (context) {
            history.append(',\${encode(AI, output.toString())},')
        }
    }
    // 非流式
    public func chat(input!: String) {
        let response = send(input)
        let output = StringReader(response.body).readToEnd() |> parse
        if (context) {
            history.append(',\${encode(AI, output)},')
        }
        return output
    }
public func preset(context: Array<(Role, String)>) {
        history.reset()
        for ((role, message) in context) {
            history.append(encode(role, message) + ',')
        }
    }






    public func reset() {
        history.reset()
    }
}

"""

let code_1_2_1 = """
enum Tree {
    Empty | Leaf(Int64) | Node(Int64, Tree, Tree)

    public func traverse(): Unit {
        match (this) {
            case Empty => ()
            case Leaf(value) => print(value)
            case Node(value, left, right) =>
                left.traverse()
                print(value)
                right.traverse()
        }
    }

    static public func generate(depth: UInt8): Tree {
        if (depth == 1) {
            return Leaf(1)
        }
        return Node(Int64(depth),
            generate(depth - 1), generate(depth - 1))
    }
}
"""

let code_1_3_1 = """
public class Cube {
    public let data = HashMap<Face, Matrix>()
    private var history = ArrayList<Rotation>()
    private static let permutation = HashMap<Face, Permutation>()

    public init() {
        reset()
    }

    static init() {
        // 每个面顺时针转动 90 度时，相邻四面的置换关系
        permutation[F] = [(L, 2.c), (U, -2.r), (R, 0.c), (D, -0.r)]
        permutation[B] = [(L, -0.c), (D, 2.r), (R, -2.c), (U, 0.r)]
        permutation[L] = [(U, 0.c), (F, 0.c), (D, 0.c), (B, 0.c)]
        permutation[R] = [(B, 2.c), (D, 2.c), (F, 2.c), (U, 2.c)]
        permutation[U] = [(L, 0.r), (B, -2.r), (R, -0.r), (F, 0.r)]
        permutation[D] = [(R, 2.r), (B, -0.r), (L, -2.r), (F, 2.r)]
    }

    public func reset() {
        history = ArrayList<Rotation>()
        for (face in [F, B, L, R, U, D]) {
            data[face] = Matrix.create(face)
        }
    }

    // 对指定面上的矩阵旋转 90 度，inverse = true 代表逆时针方向
    // 此操作不影响其他面，要配合邻边置换操作才能完成魔方的实际转动
    private func rotate(face: Face, inverse: Bool) {
        const N = 3
        let matrix = Matrix.create(face)
        let map = if (inverse) {
            { i: Int64, j: Int64 => (N - 1 - j, i) }
        } else {
            { i: Int64, j: Int64 => (j, N - 1 - i) }
        }
        for (i in 0..N) {
            for (j in 0..N) {
                let (u, v) = map(i, j)
                matrix[u][v] = data[face][i][j]
            }
        }
        data[face] = matrix
    }

    // 实现各面行/列之间的置换操作，输入是一个置换序列
    private func permute(perm: Permutation, inverse: Bool) {
        let p = if (inverse) { perm.inverse() } else { perm.clone() }
        p.reverse()
        var (lastFace, lastIndex) = p[0]
        let vector = data[lastFace][lastIndex]
        for (i in 1..p.size) {
            let (face, index) = p[i]
            data[lastFace].set(lastIndex, data[face][index])
            (lastFace, lastIndex) = (face, index)
        }
        data[lastFace].set(lastIndex, vector)
    }

    // 在魔方上按序执行 rotation 中定义的操作序列
    private func transform(rotation: Rotation, inverse: Bool): Unit {
        match (rotation) {
            case I(r) => transform(r, !inverse)
            case X(r1, r2) => // 对复合操作进行递归分解
                if (inverse) { // 逆变换需要反序
                    transform(r2, inverse)
                    transform(r1, inverse)
                } else {
                    transform(r1, inverse)
                    transform(r2, inverse)
                }
            case _ => // 各原子操作对应面先旋转 90 度，然后对相邻四个面执行置换操作
                rotate(rotation, inverse)
                permute(permutation[rotation], inverse)
        }
    }

    public func transform(rotation: Rotation) {
        transform(rotation, false)
        history.append(rotation)
        print()
        return this
    }

    public func print() {
        var prompt = ">> "
        for (rotation in history) {
            prompt += rotation.toString()
        }
        println(prompt)
        data[U].print()
        for (i in 0..3) {
            for (face in [L, F, R]) {
                data[face].print(i)
            }
            println()
        }
        data[D].print()
        data[B].print()
        println()
    }
}
"""

let code_2_1_1 = """
class AdvancedCalculator <: ILogger {
    public var lastResult: Float64 = 0.0
    private var calculationCount: Int64 = 0
    private var historyCapacity: Int64 = 100 * 2
    private var unusedProperty: String = "This is not used"
    
    public func log(message: String): Bool {
        if(logLevel > 0) {
            return true
        }
        let unusedInLog: Int64 = 55
        return false
    }

    public func performCalculation(operand1: Float64, operand2: Float64, operationType: String): Float64 {
        var result: Float64 = 0.0
        let fixedBonus: Float64 = 1.0 + 0.5 * 2.0
        var unusedLocalInCalc: Bool = true
        
        if(operationType == "add") {
            result = operand1 + operand2 + fixedBonus
        } else if(operationType == "subtract") {
            result = operand1 - operand2 + fixedBonus
        } else if(operationType == "multiply") {
            let interimResult = operand1 * operand2
            result = interimResult *(10 / 4) + fixedBonus
        } else if(operationType == "divide") {
            if(operand2 != 0) {
                result = operand1 / operand2 + fixedBonus
            } else {
                result = 0.0
            }
        }
        
        return result
    }
    
    private func utilityHelper(value: Int64, unusedParam: Bool) {
        let localConstant =(2 + 3) * 4
        var tempVar = value + localConstant
        if(tempVar > 100) { }
    }
    
    func testRanges() {
        let r1 = 0 .. 10
        let r2 =(1 + 1) ..(5 * 2):(10 / 5)
        let r3 = 0 ..=(100 - 50)
        var unusedInRangeLoopVar = "test"
        
        for(i in r2) {
            let current = i
        }

        var test = 10
        for(j in 0..10+3){
            test = test + j
        }
    }
}

func formatGreeting(name: String, age: Int64): String {
    let baseGreeting = "Hello"
    let unusedGlobalFuncVar: Int64 = 1000
    if(age >(10 + 8)) {
        return "you are an adult of age"
    } else {
        return "you are young at age"
    }
}

class DataProcessor {
    var data: Array < Int64 >
    var processed: Bool = false
    
    public func processData() {
        for(item in data) {
            let tempItem = item *(1 + 1)
            tempItem += 1
        }
        processed = true
    }
}
"""

let code_2_1_2 = """
func formatGreeting(name: String, age: Int64): String {
    var processed = false
    let baseGreeting = "Hello"
    let unusedGlobalFuncVar: Int64 = 1000
    if(age >(10 + 8)) {
        processed = true
        return "you are an adult of age"
    } else {
        return "you are young at age"
    }
}

class DataProcessor {
    var data: Array < Int64 >
    var processed: Bool = false
    
    public func processData() {
        for(item in data) {
            let tempItem = item *(1 + 1)
            tempItem += 1
        }
        processed = true
    }
}
"""

let code_2_1_3 = """
class DataProcessor {
    var data: Array < Int64 >
    var processed: Bool = false
    
    public func processData() {
        for(item in data) {
            let tempItem = item *(1 + 1)
            tempItem += 1
        }
        processed = true
    }
}
"""

let code_2_2_1 = """
class AdvancedCalculator <: ILogger {
    public var lastResult: Float64 = 0.0
    private var calculationCount: Int64 = 0
    private var historyCapacity: Int64 = 100 * 2
    private var unusedProperty: String = "This is not used"

    public mut prop result: Int64 {
        get() {
            lastResult
        }
        set(result) {
            lastResult = result
        }
    }
    
    public func log(message: String): Bool {
        if(logLevel > 0) {
            return true
        }
        let unusedInLog: Int64 = 55
        return false
    }

    public func performCalculation(operand1: Float64, operand2: Float64, operationType: String): Float64 {
        var result: Float64 = 0.0
        let fixedBonus: Float64 = 1.0 + 0.5 * 2.0
        var unusedLocalInCalc: Bool = true
        
        if(operationType == "add") {
            result = operand1 + operand2 + fixedBonus
        } else if(operationType == "subtract") {
            result = operand1 - operand2 + fixedBonus
        } else if(operationType == "multiply") {
            let interimResult = operand1 * operand2
            result = interimResult *(10 / 4) + fixedBonus
        } else if(operationType == "divide") {
            if(operand2 != 0) {
                result = operand1 / operand2 + fixedBonus
            } else {
                result = 0.0
            }
        }
        
        return result
    }
    
    private func utilityHelper(value: Int64, unusedParam: Bool) {
        let localConstant =(2 + 3) * 4
        var tempVar = value + localConstant
        if(tempVar > 100) { }
    }
    
    func testRanges() {
        let r1 = 0 .. 10
        let r2 =(1 + 1) ..(5 * 2):(10 / 5)
        let r3 = 0 ..=(100 - 50)
        var unusedInRangeLoopVar = "test"
        
        for(i in r2) {
            let current = i
        }

        var test = 10
        for(j in 0..10+3){
            test = test + j
        }
    }
}
"""

let code_2_3_1 = """
// cjlint-ignore -start !G.NAM.02 !G.EXP.03
package cj_debounce_throttle.repeater

public import std.sync.Timer

public class Repeater {
    private var lastCallTime: MonoTime
    private var lastRunTaskTime: MonoTime
    private var firstRunTask: Bool = false
    // 定时器，只有 trailing 才会使用
    private var timer: ?Timer = None

    // 配置和任务
    private let config: RepeaterConfig
    private let task: RepeaterTask
    private let throttle: Bool

    // release条件下为空实现
    @When[!debug]
    func verifyConfig() {}

    public func cancel(): Unit {
        timer = None
    }

    private func runTask() {
        firstRunTask = true
    }
}
// cjlint-ignore -end
"""

let code_3_1_1 = """
public class Cube {
    public let data = HashMap<Face, Matrix>()
    private var history = ArrayList<Rotation>()
    private static let permutation = HashMap<Face, Permutation>()

    public init() {
        reset()
    }

    static init() {
        permutation[F] = [(L, 2.c), (U, -2.r), (R, 0.c), (D, -0.r)]
        permutation[B] = [(L, -0.c), (D, 2.r), (R, -2.c), (U, 0.r)]
        permutation[L] = [(U, 0.c), (F, 0.c), (D, 0.c), (B, 0.c)]
        permutation[R] = [(B, 2.c), (D, 2.c), (F, 2.c), (U, 2.c)]
        permutation[U] = [(L, 0.r), (B, -2.r), (R, -0.r), (F, 0.r)]
        permutation[D] = [(R, 2.r), (B, -0.r), (L, -2.r), (F, 2.r)]
    }

    public func reset() {
        history = ArrayList<Rotation>()
        for (face in [F, B, L, R, U, D]) {
            data[face] = Matrix.create(face)
        }
    }

    private func rotate(face: Face, inverse: Bool) {
        const N = 3
        let matrix = Matrix.create(face)
        let map = if (inverse) {
            { i: Int64, j: Int64 => (N - 1 - j, i) }
        } else {
            { i: Int64, j: Int64 => (j, N - 1 - i) }
        }
        for (i in 0..N) {
            for (j in 0..N) {
                let (u, v) = map(i, j)
                matrix[u][v] = data[face][i][j]
            }
        }
        data[face] = matrix
    }

    private func permute(perm: Permutation, inverse: Bool) {
        let p = if (inverse) { perm.inverse() } else { perm.clone() }
        p.reverse()
        var (lastFace, lastIndex) = p[0]
        let vector = data[lastFace][lastIndex]
        for (i in 1..p.size) {
            let (face, index) = p[i]
            data[lastFace].set(lastIndex, data[face][index])
            (lastFace, lastIndex) = (face, index)
        }
        data[lastFace].set(lastIndex, vector)
    }

    private func transform(rotation: Rotation, inverse: Bool): Unit {
        match (rotation) {
            case I(r) => transform(r, !inverse)
            case X(r1, r2) => 
                if (inverse) { 
                    transform(r2, inverse)
                    transform(r1, inverse)
                } else {
                    transform(r1, inverse)
                    transform(r2, inverse)
                }
            case _ => 
                rotate(rotation, inverse)
                permute(permutation[rotation], inverse)
        }
    }

    public func transform(rotation: Rotation) {
        transform(rotation, false)
        history.append(rotation)
        print()
        return this
    }

    public func print() {
        var prompt = ">> "
        for (rotation in history) {
            prompt += rotation.toString()
        }
        println(prompt)
        data[U].print()
        for (i in 0..3) {
            for (face in [L, F, R]) {
                data[face].print(i)
            }
            println()
        }
        data[D].print()
        data[B].print()
        println()
    }
}
"""

let code_3_1_2 = """
// 群聊程序-服务器
import std.collection.*
import std.collection.concurrent.*
import std.console.*
import std.socket.*
import std.sync.*
import std.time.Duration

const PORT: UInt16 = 24621
const BUFFER_SIZE = 1024
var g_quit = false

func controller() {
    spawn {
        while (!g_quit) {
            let key = Console.stdIn.read().getOrDefault {r' '}
            if (key == r'q' || key == r'Q') {
                g_quit = true
            }
        }
    }
}

extend TcpSocket {
    public func tryWrite(data: Array<Byte>) {
        try { this.write(data) } catch (e: SocketException) {
            if (!this.isClosed()) { this.close() }
            return false
        }
        return true
    }
}

main() {
    let messages = NonBlockingQueue<(TcpSocket, Array<Byte>)>()
    let members = LinkedList<TcpSocket>() // 群聊成员-客户端
    let server = TcpServerSocket(bindAt: PORT) // 服务端
    server.bind()
    controller()

    // 和新的客户端建立连接
    let mutex = ReentrantMutex()
    let monitor = Monitor()
    spawn {
        while (!g_quit) {
            let client = server.accept()
            synchronized (mutex) {
                members.append(client)
            }
            // 每个连接要处理的任务
            spawn {
                while (!g_quit) {
                    let data = Array<Byte>(BUFFER_SIZE, item: 0)
                    try { client.read(data) } catch (e: SocketException) {
                        return // 遇到异常终止此线程，由转发线程清理资源
                    }
                    println(String.fromUtf8(data))
                    messages.enqueue((client, data))
                    synchronized (monitor) { monitor.notify() }
                }
            }
        }
    }

    // 转发消息到所有客户端，实现群聊
    while (!g_quit) {
        // 此处 Monitor 仅用于避免 while 空转，可以注释掉以下三行代码对比进程 CPU 消耗情况
        synchronized (monitor) {
            monitor.wait(timeout: Duration.millisecond * 100)            
        }
        while (let Some((client, data)) <- messages.dequeue()) {
            mutex.lock()
            // 遍历群聊成员，转发消息并清理无效客户端
            members.removeIf { socket =>
                if (refEq(client, socket)) { // 不必转发给消息源
                    return false
                }
                !socket.tryWrite(data)
            }
            mutex.unlock()
        }
    }
    // 退出时通知所有客户端
    for (client in members) {
        if (client.tryWrite("Server Exit".toArray())) {
            client.close()
        }
    }
    server.close()
}
"""

let code_3_1_3 = """
package demo

import std.collection.*
/*
定义管道扩展点
 */
public class ApplicationBuilder {
    private let _middlewares = ArrayList<(RequestDelegate) -> RequestDelegate>()

    public func use(middleware: (RequestDelegate) -> RequestDelegate) {
        _middlewares.add(middleware)
    }

    public func use(middleware: (Context, () -> Unit) -> Unit) {
        _middlewares.add({
            next => {
                context => middleware(context) {
                    next(context)
                }
            }
        })
    }

    public func use<TMiddleware>(middleware: TMiddleware) where TMiddleware <: IMiddleware {
        use(middleware.invoke)
    }

    public func build(): RequestDelegate {
        var app: RequestDelegate = {
            context =>
            context.status = 404
            println("404 Not Found")
        }
        var size = _middlewares.size - 1
        while (size >= 0) {
            app = _middlewares[size](app)
            size -= 1
        }
        return app
    }
}
"""

let code_3_2_1 = """
package cangjieWeb.mysql
import std.database.sql.{UpdateResult}
public class MySqlUpdateResult <: UpdateResult {

    private var _rowCount: Int64 
    private var _lastInsertId: Int64 

    public init(rowCount: Int64, lastInsertId: Int64) {
        this._rowCount = rowCount
        this._lastInsertId = lastInsertId
    }


    public prop lastInsertId: Int64 {
        get() {
            return _lastInsertId
        }
    }
    public prop rowCount: Int64 {
        get() {
            return _rowCount
        }
    }

    public func close() {
        
    }

    public func isClosed(): Bool {
        return false
    } 
}
"""

let code_4_1_1 = """
class AdvancedCalculator <: ILogger {
    public var lastResult: Float64 = 0.0
    private var calculationCount: Int64 = 0
    private var historyCapacity: Int64 = 100 * 2
    private var unusedProperty: String = "This is not used"

    public func log(message: String): Bool {
        if(logLevel > 0) {
            return true
        }
        let unusedInLog: Int64 = 55
        return false
    }

    public func performCalculation(operand1: Float64, operand2: Float64, operationType: String): Float64 {
        var result: Float64 = 0.0
        let fixedBonus: Float64 = 1.0 + 0.5 * 2.0
        var unusedLocalInCalc: Bool = true
        
        if(operationType == "add") {
            result = operand1 + operand2 + fixedBonus
        } else if(operationType == "subtract") {
            result = operand1 - operand2 + fixedBonus
        } else if(operationType == "multiply") {
            let interimResult = operand1 * operand2
            result = interimResult *(10 / 4) + fixedBonus
        } else if(operationType == "divide") {
            if(operand2 != 0) {
                result = operand1 / operand2 + fixedBonus
            } else {
                result = 0.0
            }
        }
        
        return result
    }
    
    private func utilityHelper(value: Int64, unusedParam: Bool) {
        let localConstant =(2 + 3) * 4
        var tempVar = value + localConstant
        if(tempVar > 100) { }
    }
    
    func testRanges() {
        let r1 = 0 .. 10
        let r2 =(1 + 1) ..(5 * 2):(10 / 5)
        let r3 = 0 ..=(100 - 50)
        var unusedInRangeLoopVar = "test"
        
        for(i in r2) {
            let current = i
        }

        var test = 10
        for(j in 0..13){
            test = test + j
        }
    }
}

func formatGreeting(name: String, age: Int64): String {
    let baseGreeting = "Hello"
    let unusedGlobalFuncVar: Int64 = 1000 % 3
    if(age >(10 + 8)) {
        return "you are an adult of age"
    } else {
        return "you are young at age"
    }
}

class DataProcessor {
    var data: Array < Int64 >
    var processed: Bool = false
    
    public func processData() {
        for(item in data) {
            let tempItem = item *(1 + 1)
            tempItem += 1
        }
        processed = true
    }
}
"""

let code_4_2_1 = """
package demo

public interface IMiddleware {
    func invoke(context: Context, next: () -> Unit): Unit
}
"""

let code_5_1_1 = """
package cangjieWeb.mysql
import std.database.sql.{QueryResult, ColumnInfo, SqlDbType, SqlInteger, SqlVarchar}
import std.collection.{ArrayList}
import cangjieWeb.utils.ByteArrayUtils
public class MysqlQueryResult <: QueryResult {

    private let columns: ArrayList<MySqlField>
    private let rows: ArrayList<Array<Byte>>
    private var tempRowsIndex = 0
    private var nullBitMapStartPos = 1
    private var nullBitMapEndPos = 0
    private var tempRowPos = 0

    public func next(values: Array<SqlDbType>): Bool {
        var rowSize = tempRowPos + 2
        tempRowPos = nullBitMapStartPos + 1
        if (tempRowsIndex < rows) {
            for(i in 0 .. values) {
                
            }
            tempRowsIndex += 1
            return true
        }
        return false
    }
}
"""

let code_5_2_1 = """
// CFFI：调用 C 标准库 signal 函数处理系统信号
// LJJ 2024.12.10
import std.sync.sleep
import std.time.Duration

foreign func signal(value: Int32, handler: CFunc<(Int32) -> Unit>): Unit
const SIGINT: Int32 = 2

@C
func handler(value: Int32) {
    // do nothing
}

unsafe main() {
    signal(SIGINT, handler)
    while (true) {
        println('sleep 1 second')
        sleep(Duration.second)
    }
}
"""

@Test
class GenerateCodeSignatureTest {

    @TestCase
    private func testGenerateCodeSignature() {
        println(CJCodeTool.generateCodeSignature(code_1_1_1))
    }

    @TestCase
    private func testGenerateCodeSignature2() {
        println(CJCodeTool.generateCodeSignature(code_1_1_2))
    }

    @TestCase
    private func testGenerateCodeSignature3() {
        println(CJCodeTool.generateCodeSignature(code_1_2_1))
    }

    @TestCase
    private func testGenerateCodeSignature4() {
        println(CJCodeTool.generateCodeSignature(code_1_3_1))
    }
}

@Test
class RefractorVariableTest {

    @TestCase
    private func testRefractorVariable() {
        println(CJCodeTool.refractorVariable(code_2_1_1, "AdvancedCalculator", "result", "newResult"))
    }

    @TestCase
    private func testRefractorVariable2() {
        println(CJCodeTool.refractorVariable(code_2_1_2, "formatGreeting", "processed", "newProcessed"))
    }

    @TestCase
    private func testRefractorVariable3() {
        println(CJCodeTool.refractorVariable(code_2_1_3, "DataProcessor.processData", "data", "newData"))
    }

    @TestCase
    private func testRefractorVariable4() {
        println(CJCodeTool.refractorVariable(code_2_2_1, "AdvancedCalculator", "lastResult", "newLastResult"))
    }

    @TestCase
    private func testRefractorVariable5() {
        println(CJCodeTool.refractorVariable(code_2_3_1, "Repeater", "timer", "newTimer"))
    }
}

@Test
class GenerateDocumentTest {

    @TestCase
    private func testGenerateDocument() {
        println(CJCodeTool.generateDocument(code_3_1_1, "Cube"))
    }

    @TestCase
    private func testGenerateDocument2() {
        println(CJCodeTool.generateDocument(code_3_1_2, "controller"))  
    }

    @TestCase
    private func testGenerateDocument3() {
        println(CJCodeTool.generateDocument(code_3_1_3, "ApplicationBuilder.build"))
    }

    @TestCase
    private func testGenerateDocument4() {
        println(CJCodeTool.generateDocument(code_3_2_1, "MySqlUpdateResult.nullFunc"))
    }
}

@Test
class FoldConstantTest {

    @TestCase
    private func testFoldConstant() {
        println(CJCodeTool.foldConstant(code_4_1_1))
    }

    @TestCase
    private func testFoldConstant2() {
        println(CJCodeTool.foldConstant(code_4_2_1))
    }
}

@Test
class findUnusedVariablesTest {

    @TestCase
    private func findUnusedVariablesTest() {
        println(CJCodeTool.findUnusedVariables(code_5_1_1))
    }

    @TestCase
    private func findUnusedVariablesTest2() {
        println(CJCodeTool.findUnusedVariables(code_5_2_1))
    }
}