package playground

import std.ast.*
import std.fs.*

let code = """
interface I1 {
    mut prop size: Int64
}

class C <: I1 {
    private var mySize = 1*2

    func myfunc(a: Float64, n: Int64) : Float64 {
        for(i : Int64 in 0..=n) {
            a *= (i + 2 * 42)
        }
        return a
    }
}

func myfunc(a: Float64, n: Int64) : Float64 {
    for(i : Int64 in 0..=n) {
        a *= (i + 3 * 4)
    }
    let a = 1 + 2
    let b = ((3 * 4) + 5) + (a + 4) * (5 * 3 + 9)
    var c = 31 / 4
    var d = 114.514 + 111111000
    return a / ((2.5 * 100) + 4 * a + 4)
}

func testRange() {
    let r5 = 0..10   
    let r6 = 0..10 : 1 + 2

    let r7 = 10..3*4+2 : 1 
    let r8 = 0..10 : 1 + 2 - 3
    let r9 = 10..=0 : (1 + 2) * 3
    let r10 = (1+2-3+4-5+6)..=10 : -1
}
"""

@Test
class GenerateCodeSignatureTest {

    @TestCase
    private func testGenerateCodeSignature() {
        println(CJCodeTool.generateCodeSignature(code))
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
    private let path = "C.myfunc"

    @TestCase
    private func testGenerateDocument() {
        println(CJCodeTool.generateDocument(code, path))
    }
}