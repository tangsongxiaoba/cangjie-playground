package playground

import std.ast.*
import std.core.*

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
    func insertBefore(index: Int64, newTokens: Tokens): Tokens {
        return this[0..index].append(newTokens).append(this[index..])
    }
}

class MyToken {
    let token: Token

    public init(token: Token) {
        this.token = token
    }

    public func getToken() {
        return this.token
    }
}

extend MyToken <: Equatable<MyToken> & Hashable {
    public operator func ==(right: MyToken): Bool{
        this.token.toString() == right.token.toString()
    }

    public operator func !=(right: MyToken): Bool{
        this.token.toString() != right.token.toString()
    }

    public func hashCode() : Int64 {
        Int64(this.token.toString().hashCode())
    }
}