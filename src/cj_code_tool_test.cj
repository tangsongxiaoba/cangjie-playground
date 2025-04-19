package playground

import std.ast.*

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
    return a
}


main() : Int64 {
    let a = 1 + 2
    let b = ((3 * 4) + 5) + (a + 4) * 5
    var c = 31 / 4
    var d = 114.514 + 11111100000
    println("abcd is 111111 * 12")
    return a
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