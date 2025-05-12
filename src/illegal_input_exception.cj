package playground

import std.ast.*

class IllegalInputException <: Exception {
    var node: Node

    public init(node: Node) {
        super('ILLEGAL INPUT')
        this.node = node
    }

    public func dump() {
        node.dump()
    }

    public func toString(): String {
        return "// Meet with illegal input:\n" + node.toTokens().toString()
    }
    
    public override func getClassName(): String {
        "IllegalInputException"
    }
}