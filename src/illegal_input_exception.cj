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
        return node.toTokens().toString()
    }
    
    public override func getClassName(): String {
        "IllegalInputException"
    }
}