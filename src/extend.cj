package playground

import std.ast.*

extend String {
    func toProgram(): Program {
        return parseProgram(cangjieLex(this))
    }
}

extend Token {
    func toString(): String {
        return this.toTokens().toString()
    }
}

extend Program {
    func toString(): String {
        return this.toTokens().toString()
    }
}