package playground

import std.ast.*
import std.fs.*

func readFile(): String {
    let file = File.openRead("src/Cangjie-Examples-a/BTree/class.cj")
    let bytes = file.readToEnd()
    var code = ""
    for (byte in bytes) {
        code += Rune(byte).toString()
    }
    return code
}

@Test
class GenerateCodeSignatureTest {
    private let code = readFile()

    @TestCase
    private func testGenerateCodeSignature() {
        let sig = CJCodeTool.generateCodeSignature(code)
        println(sig)
    }
}

@Test
class FindDeclByPathTest {
    private let code = """
interface I1 {
    mut prop size: Int64
}

class C <: I1 {
    private var mySize = 0

    public mut prop size: Int64 {
        get() {
            mySize
        }
        set(value) {
            mySize = value
        }
    }

    public func getSize() {
        mySize
    }
}

public func testC() {
    let a: I1 = C()
    a.size = 5
    println(a.size)
}
"""

    @TestCase
    private func testFindDeclByPath() {
        let prog = code.toProgram()
        let paths = CJCodeTool.splitPath("C.getSize")
        let decl = CJCodeTool.findDeclByPath(prog, paths)
        decl.dump()
    }
}

@Test
class FoldConstantTest {
    private let code = 
"""

let a = 1 + 2
let b = ((3 * 4) + 5) + (a + 4) * (5 * 3 + 9)
var c = 31 / 4
var d = 114.514 + 111111000

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

    @TestCase
    private func testFoldConstant() {
        println(CJCodeTool.foldConstant(code))
    }
}

@Test
class GenerateDocumentTest {
    private let code = """
interface I1 {
    mut prop size: Int64
}

class C <: I1 {
    private var mySize = 0

    public mut prop size: Int64 {
        get() {
            mySize
        }
        set(value) {
            mySize = value
        }
    }

    public func getSize() {
        mySize
    }
}

public func testC() {
    let a: I1 = C()
    a.size = 5
    println(a.size)
}
"""
    private let path = "C.getSize"

    @TestCase
    private func testGenerateDocument() {
        println(CJCodeTool.generateDocument(code, path))
    }
}