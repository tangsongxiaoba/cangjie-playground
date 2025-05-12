package playground

import std.ast.*
import std.fs.*

let code = """
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

@Test
class findUnusedVariablesTest {

    @TestCase
    private func findUnusedVariablesTest() {
        println(CJCodeTool.findUnusedVariables(code))
    }
}

@Test
class GenerateCodeSignatureTest {

    @TestCase
    private func testGenerateCodeSignature() {
        println(CJCodeTool.generateCodeSignature(code))
    }
}

@Test
class RefractorVariableTest {

    @TestCase
    private func testRefractorVariable() {
        println(CJCodeTool.refractorVariable(code, "C", "mySize", "yourSize"))
    }
}

@Test
class FoldConstantTest {

    @TestCase
    private func testFoldConstant() {
        println(CJCodeTool.foldConstant(code))
    }
}

@Test
class GenerateDocumentTest {

    @TestCase
    private func testGenerateDocument() {
        var res = code
        res = CJCodeTool.generateDocument(res, "C")
        res = CJCodeTool.generateDocument(res, "C.testRange")
        res = CJCodeTool.generateDocument(res, "C.myfunc")
        println(res)
    }
}