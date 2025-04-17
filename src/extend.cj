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

extend Tokens {
    func insert(index: Int64, newTokens: Tokens) : Tokens {
        var front = this[0..index]
        var back = this[index..this.size]
        return front.append(newTokens).append(back)
    }
}