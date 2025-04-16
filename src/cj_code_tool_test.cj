package playground

import std.ast.*

@Test
class CJCodeToolTest {
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
    private func testFtindDeclByPah() {
        let prog = code.toProgram()
        let paths = CJCodeTool.splitPath("C.getSize")
        let decl = CJCodeTool.findDeclByPath(prog, paths)
        decl.dump()
    }
}
