package playground

import std.ast.*
import std.collection.*
import std.convert.*

class IllegalInputException <: Exception {
    public init() {
        super("ILLEGAL INPUT")
    }
    
    public override func getClassName(): String {
        "IllegalInputException"
    }
}

class CJCodeTool {
    static func generateCodeSignature(code: String): String {
        var signature = Tokens()
        let tks = cangjieLex(code)
        var start = 0
        while (start < tks.size) {
            try {
                let (decl, mid) = parseDeclFragment(tks, startFrom: start)
                start = mid 

                for (m in decl.modifiers) {
                    signature += m.toTokens()
                }
                signature += decl.keyword
                signature += decl.identifier

                if (decl is ClassDecl) {
                    signature += parseClassDecl(decl)
                } else if (decl is InterfaceDecl) {
                    signature += parseInterfaceDecl(decl)
                } else if (decl is FuncDecl) {
                    signature += parseFuncDecl(decl)
                } else {
                    throw Exception("decl is unknown")
                }
            } catch (e: Exception) {
                return "ILLEGAL INPUT"
            }
            
            if (start < tks.size) {
                signature += Token(TokenKind.NL) // add "\n"
                signature += Token(TokenKind.NL)
            }
        }
        return signature.toString()
    }

    private static func parseClassDecl(decl: Decl): Tokens {
        var signature = Tokens()
        let classDecl = decl as ClassDecl
        match (classDecl) {
            case Some(classDecl) => 
                let superTypes = classDecl.superTypes // superTypes can be null
                if (superTypes.size > 0) {
                    signature += classDecl.upperBound
                    var hasSuperTypeBitAnds = false
                    for (s in superTypes) {
                        if (hasSuperTypeBitAnds) {
                            signature += classDecl.superTypeBitAnds[0]
                        }
                        signature += s.toTokens()
                        hasSuperTypeBitAnds = true
                    }
                }

                let body = classDecl.body
                if (body.decls.size > 0) {
                    signature += body.lBrace
                    signature += Token(TokenKind.NL)
                    let bodyDecls = body.decls
                    signature += parseBodyDecls(bodyDecls)
                    signature += Token(TokenKind.NL)
                    signature += body.rBrace
                }
            case None => 
                throw ASTException("decl is not a classDecl")
        }

        return signature
    }

    private static func parseInterfaceDecl(decl: Decl): Tokens {
        var signature = Tokens()
        let interfaceDecl = decl as InterfaceDecl
        match (interfaceDecl) {
            case Some(interfaceDecl) => 
                let superTypes = interfaceDecl.superTypes // superTypes can be null
                if (superTypes.size > 0) {
                    signature += interfaceDecl.upperBound
                    var hasSuperTypeBitAnds = false
                    for (s in superTypes) {
                        if (hasSuperTypeBitAnds) {
                            signature += interfaceDecl.superTypeBitAnds[0]
                        }
                        signature += s.toTokens()
                        hasSuperTypeBitAnds = true
                    }
                }

                let body = interfaceDecl.body
                if (body.decls.size > 0) {
                    signature += body.lBrace
                    signature += Token(TokenKind.NL)
                    let bodyDecls = body.decls
                    signature += parseBodyDecls(bodyDecls)
                    signature += Token(TokenKind.NL)
                    signature += body.rBrace
                }
            case None => 
                throw ASTException("decl is not a interfaceDecl")
        }
        return signature
    }

    private static func parseFuncDecl(decl: Decl): Tokens {
        var signature = Tokens()
        let funcDecl = decl as FuncDecl
            match (funcDecl) {
            case Some(funcDecl) =>
                signature += funcDecl.lParen
                let FuncParams = funcDecl.funcParams // funcParams can be null
                if (FuncParams.size > 0) {
                    for (p in FuncParams) {
                        signature += p.toTokens()
                    }
                }
                signature += funcDecl.rParen
                try {
                    let declType = funcDecl.declType // declType can be null
                    signature += funcDecl.colon
                    signature += declType.toTokens()
                } catch (e: ASTException) {}
            case None =>
                throw ASTException("decl is not a funcDecl")
        }
        return signature
    }

    private static func parseBodyDecls(decls: ArrayList<Decl>): Tokens {
        var signature = Tokens()
        var isFirstDecl = true
        for (decl in decls) {
            if (!isFirstDecl) {
                signature += Token(TokenKind.NL)
                signature += Token(TokenKind.NL)
            }
            isFirstDecl = false
            for (m in decl.modifiers) {
                signature += m.toTokens() // modifiers can be null
            }
            if (decl.keyword.toString() == decl.identifier.toString()) {
                // keyword and identifier are the same: "init"
                signature += decl.keyword
            } else {
                signature += decl.keyword
                signature += decl.identifier
            }
            if (decl is VarDecl) {
                signature += parseVarDecl(decl)
            } else if (decl is PropDecl) {
                signature += parsePropDecl(decl)
            } else if (decl is FuncDecl) {
                signature += parseFuncDecl(decl)
            } else {
                throw Exception("decl is unknown")
            }
        }
        return signature
    }

    private static func parseVarDecl(decl: Decl): Tokens {
        var signature = Tokens()
        let varDecl = decl as VarDecl
        match (varDecl) {
            case Some(varDecl) =>
                try {
                    let declType = varDecl.declType // declType can be null
                    signature += varDecl.colon
                    signature += declType.toTokens()
                } catch (e: ASTException) {}
            case None =>
                throw ASTException("decl is not a varDecl")
        }
        return signature
    }

    private static func parsePropDecl(decl: Decl): Tokens {
        var signature = Tokens()
        let propDecl = decl as PropDecl
        match (propDecl) {
            case Some(propDecl) =>
                try {
                    let declType = propDecl.declType // declType can be null
                    signature += propDecl.colon
                    signature += declType.toTokens()
                } catch (e: ASTException) {}
            case None =>
                throw ASTException("decl is not a propDecl")
        }
        return signature
    }

    static func refractorVariable(code: String, path: String, oldName: String, newName: String): String {
        try {
            var prog = code.toProgram()
            var decl = findDeclByPath(prog, splitPath(path))
            refractorDecl(decl, oldName, newName)
            return prog.toTokens().toString()
        } catch (e: IllegalInputException) {
            return e.message
        } catch (e: Exception) {
            throw e
        }
    }

    private static func replaceToken(oldToken: Token, oldValue: String, newValue: String, tokenKind: TokenKind): Token {
        if (oldToken.toString() == oldValue) {
            return Token(tokenKind, newValue)
        }
        return oldToken
    }

    private static func refractorDecl(decl: Decl, oldName: String, newName: String): Unit {
        decl.identifier = replaceToken(decl.identifier, oldName, newName, TokenKind.IDENTIFIER)
        if (decl is ClassDecl) {
            let classDecl = (decl as ClassDecl).getOrThrow()
            for (superType in classDecl.superTypes) {
                refractorTypeNode(superType, oldName, newName)
            }
            refractorBody(classDecl.body, oldName, newName)
        } else if (decl is FuncDecl) {
            let funcDecl = (decl as FuncDecl).getOrThrow()
            for (p in funcDecl.funcParams) {
                p.identifier = replaceToken(p.identifier, oldName, newName, TokenKind.IDENTIFIER)
            }
            refractorBlock(funcDecl.block, oldName, newName)
        } else if (decl is VarDecl) {
            let varDecl = (decl as VarDecl).getOrThrow()
            try {
                refractorExpr(varDecl.expr, oldName, newName) // expr can be null
            } catch (e: ASTException) {}
            try {
                refractorPattern(varDecl.pattern, oldName, newName) // pattern can be null
            } catch (e: ASTException) {}
        } else {
            throw IllegalInputException()
        }
    }

    private static func refractorBody(body: Body, oldName: String, newName: String) {
        for (decl in body.decls) {
            refractorDecl(decl, oldName, newName)
        }
    }

    private static func refractorExpr(expr: Expr, oldName: String, newName: String): Unit {
        if (expr is AssignExpr) {
            let assignExpr = (expr as AssignExpr).getOrThrow()
            refractorExpr(assignExpr.leftExpr, oldName, newName)
            refractorExpr(assignExpr.rightExpr, oldName, newName)
        } else if (expr is BinaryExpr) {
            let binaryExpr = (expr as BinaryExpr).getOrThrow()
            refractorExpr(binaryExpr.leftExpr, oldName, newName)
            refractorExpr(binaryExpr.rightExpr, oldName, newName)
        } else if (expr is Block) {
            refractorBlock((expr as Block).getOrThrow(), oldName, newName)
        } else if (expr is ForInExpr) {
            let forInExpr = (expr as ForInExpr).getOrThrow()
            refractorBlock(forInExpr.block, oldName, newName)
            refractorExpr(forInExpr.expr, oldName, newName)
            refractorPattern(forInExpr.pattern, oldName, newName)
        } else if (expr is IfExpr) {
            let ifExpr = (expr as IfExpr).getOrThrow()
            refractorExpr(ifExpr.condition, oldName, newName)
            refractorExpr(ifExpr.elseExpr, oldName, newName)
            refractorBlock(ifExpr.ifBlock, oldName, newName)
        } else if (expr is LitConstExpr) {
        } else if (expr is ParenExpr) {
            let parenExpr = (expr as ParenExpr).getOrThrow()
            refractorExpr(parenExpr.parenthesizedExpr, oldName, newName)
        } else if (expr is RangeExpr) {
            let rangeExpr = (expr as RangeExpr).getOrThrow()
            try {
                refractorExpr(rangeExpr.start, oldName, newName) // start can be null
            } catch (e: ASTException) {}
            try {
                refractorExpr(rangeExpr.end, oldName, newName) // end can be null
            } catch (e: ASTException) {}
            try {
                refractorExpr(rangeExpr.step, oldName, newName) // step can be null
            } catch (e: ASTException) {}
        } else if (expr is RefExpr) {
            let refExpr = (expr as RefExpr).getOrThrow()
            replaceToken(refExpr.identifier, oldName, newName, TokenKind.IDENTIFIER)
            for (t in refExpr.typeArguments) {
                refractorTypeNode(t, oldName, newName)
            }
        } else if (expr is ReturnExpr) {
            let returnExpr = (expr as ReturnExpr).getOrThrow()
            try {
                refractorExpr(returnExpr.expr, oldName, newName) // expr can be null
            } catch (e: ASTException) {}
        } else if (expr is UnaryExpr) {
            let unaryExpr = (expr as UnaryExpr).getOrThrow()
            refractorExpr(unaryExpr.expr, oldName, newName)
        } else {  
            throw IllegalInputException()
        }
    }

    private static func refractorPattern(pattern: Pattern, oldName: String, newName: String) {
        if (pattern is VarPattern) {
            let varPattern = (pattern as VarPattern).getOrThrow()
            replaceToken(varPattern.identifier, oldName, newName, TokenKind.IDENTIFIER)
        } else {
            throw IllegalInputException()
        }
    }

    private static func refractorTypeNode(typeNode: TypeNode, oldName: String, newName: String): Unit {
        typeNode.typeParameterName = replaceToken(typeNode.typeParameterName, oldName, newName, TokenKind.IDENTIFIER)
        if (typeNode is RefType) {
            let refType = (typeNode as RefType).getOrThrow()
            for (t in refType.typeArguments) {
                refractorTypeNode(t, oldName, newName)
            }
        } else if (typeNode is PrimitiveType) { 
            // do nothing
        } else {
            throw IllegalInputException()
        }
    }

    private static func refractorBlock(block: Block, oldName: String, newName: String) {
        for (node in block.nodes) {
            if (node is Expr) {
                refractorExpr((node as Expr).getOrThrow(), oldName, newName)
            } else if (node is Decl) {
                refractorDecl((node as Decl).getOrThrow(), oldName, newName)
            } else if (node is Body) {
                refractorBody((node as Body).getOrThrow(), oldName, newName)
            } else if (node is Pattern) {
                refractorPattern((node as Pattern).getOrThrow(), oldName, newName)
            } else if (node is TypeNode) {
                refractorTypeNode((node as TypeNode).getOrThrow(), oldName, newName)
            } else if (node is ImportContent || node is ImportList || node is Modifier || node is PackageHeader) {
            } else {
                throw Exception("node is unknown")
            }
        }
    }

    static func generateDocument(code: String, path: String): String {
        func addSpace(n: Int32, str: String) : StringBuilder {
            let strList = str.split('\n')
            var tempBuilder = StringBuilder()
            for(str in strList) {
                for(i in 1..n) {
                    tempBuilder.append(' ')
                }
                tempBuilder.append(str + '\n')
            }
            return tempBuilder
        }
        func getIndex(tokens: Tokens, decl: Decl) : Option<Int64> {
            var i = 0
            let firstToken = decl.toTokens().get(0)
            for(token in tokens) {
                if(token == firstToken){
                    return i
                }
                i++
            }
            return None
        }
        func getDoc(code: String) : String {
            let robot = LLM(url: 'https://api.siliconflow.cn/v1/chat/completions',
                            key: 'sk-pqwthdmbesdwldfllezgjildshqhezpwzjbupqolzijkxjoa',
                            model: 'deepseek-ai/DeepSeek-V3',
                            context: true)
            return robot.chat(code)
        }
        var program = code.toProgram()
        var programTokens = program.toTokens()
        var decl = findDeclByPath(program, splitPath(path))
        var strDecl = decl.toTokens().toString()
        let col = decl.toTokens().get(0).pos.column
        let line = decl.toTokens().get(0).pos.line
        let ret = getDoc(strDecl)
        var retBuilder = StringBuilder()
        retBuilder.append(addSpace(col, '/*'))
        retBuilder.append(addSpace(col, ret))
        retBuilder.append(addSpace(col, '*/'))

        let index : Int64 = getIndex(programTokens, decl) ?? throw Exception("cannot get index of decl")
        
        return programTokens.insert(index, cangjieLex(retBuilder.toString())).toString()
    }

    /*
    折叠常量
    */
    static func foldConstant(str: String) : String {
        try {
            var program = str.toProgram()
            for(decl in program.decls) {
                foldConstForDecl(decl)
            }
            return program.toString()
        } catch(e: Exception) {
            return "ILLEGAL INPUT"
        }
    }

    /*
    对定义进行折叠常量处理
    */
    private static func foldConstForDecl(decl: Decl): Unit {
        if (decl is VarDecl) {
            var ndecl = (decl as VarDecl).getOrThrow()
            ndecl.expr = foldConstForExpr(ndecl.expr)
        }
        else if (decl is FuncDecl) {
            var ndecl = (decl as FuncDecl).getOrThrow()
            foldConstForBlock(ndecl.block)
        }
        else if (decl is ClassDecl) {
            var ndecl = (decl as ClassDecl).getOrThrow()
            for(ddecl in ndecl.body.decls) {
                foldConstForDecl(ddecl)
            }
        } else {
            throw Exception('unknown decl type')
        }
    }

    /*
    对块进行折叠常量处理
    */
    static func foldConstForBlock(block : Block) {
        for(node in block.nodes) {
            if (node is Expr) {
                var expr = (node as Expr).getOrThrow()
                expr = foldConstForExpr(expr)
            }
            else if (node is Decl) {
                var decl = (node as Decl).getOrThrow()
                foldConstForDecl(decl)
            }
        }
    }

    /*
    对表达式进行折叠常量处理
    */
    static func foldConstForExpr(expr: Expr) : Expr {
        if (expr is LitConstExpr) {
            return expr
        }
        if (expr is BinaryExpr) {
            var binary_expr = (expr as BinaryExpr).getOrThrow()
            binary_expr.leftExpr = foldConstForExpr(binary_expr.leftExpr)
            binary_expr.rightExpr = foldConstForExpr(binary_expr.rightExpr)
            return calExpr(binary_expr)
        }
        if (expr is ParenExpr) {
            var paren_expr = (expr as ParenExpr).getOrThrow()
            paren_expr.parenthesizedExpr = foldConstForExpr(paren_expr.parenthesizedExpr)
            return calExpr(paren_expr.parenthesizedExpr)
        }

        if (expr is AssignExpr) {
            var assign_expr = (expr as AssignExpr).getOrThrow()
            assign_expr.rightExpr = foldConstForExpr(assign_expr.rightExpr)
        } else if (expr is ForInExpr) {
            var for_in_expr = (expr as ForInExpr).getOrThrow()
            foldConstForBlock(for_in_expr.block)
        } else if (expr is WhileExpr) {
            var while_expr = (expr as WhileExpr).getOrThrow()
            while_expr.condition = foldConstForExpr(while_expr.condition)
            foldConstForBlock(while_expr.block)
        } else if (expr is IfExpr) {
            var if_expr = (expr as IfExpr).getOrThrow()
            if_expr.condition = foldConstForExpr(if_expr.condition)
            try {
                if_expr.elseExpr = foldConstForExpr(if_expr.elseExpr)
            } catch (e: ASTException) {}
            foldConstForBlock(if_expr.ifBlock)
        } else if (expr is ReturnExpr) {
            var ret_expr = (expr as ReturnExpr).getOrThrow()
            ret_expr.expr = foldConstForExpr(ret_expr.expr)
        } else if (expr is RangeExpr) {
            var range_expr = (expr as RangeExpr).getOrThrow()
            try{
                range_expr.start = foldConstForExpr(range_expr.start)
            } catch(e: ASTException) {}
            try{
                range_expr.end = foldConstForExpr(range_expr.end)
            } catch(e: ASTException) {}
            try{
                range_expr.step = foldConstForExpr(range_expr.step)
            } catch(e: ASTException) {}
        } else if (expr is UnaryExpr || expr is RefExpr) {
            // No need to fold?
        }
        else {
            // unexpected expression type
            throw Exception('unknown expr type')
        }
        return expr
    }

    /*
    如果表达式全部为常数，计算表达式的值
    */
    static func calExpr(expr : Expr) : Expr {
        if(expr is LitConstExpr) {
            return (expr as LitConstExpr).getOrThrow()
        }
        if(expr is BinaryExpr) {
            var binaryExpr = (expr as BinaryExpr).getOrThrow()
            var leftExpr = binaryExpr.leftExpr
            var rightExpr = binaryExpr.rightExpr
            
            if(leftExpr is LitConstExpr && rightExpr is LitConstExpr) {
                var leftExpr = (leftExpr as LitConstExpr).getOrThrow()
                var rightExpr = (rightExpr as LitConstExpr).getOrThrow()
                
                if(binaryExpr.op.kind == TokenKind.ADD) {
                    if(leftExpr.literal.kind == INTEGER_LITERAL && rightExpr.literal.kind == INTEGER_LITERAL) {
                        var constant = Int64.parse(leftExpr.literal.value) + Int64.parse(rightExpr.literal.value)
                        return LitConstExpr(quote($(constant)))
                    } else {
                        var constant = Float64.parse(leftExpr.literal.value) + Float64.parse(rightExpr.literal.value)
                        return LitConstExpr(quote($(constant)))
                    }
                } else if (binaryExpr.op.kind == TokenKind.SUB) {
                    if(leftExpr.literal.kind == INTEGER_LITERAL && rightExpr.literal.kind == INTEGER_LITERAL) {
                        var constant = Int64.parse(leftExpr.literal.value) - Int64.parse(rightExpr.literal.value)
                        return LitConstExpr(quote($(constant)))
                    } else {
                        var constant = Float64.parse(leftExpr.literal.value) - Float64.parse(rightExpr.literal.value)
                        return LitConstExpr(quote($(constant)))
                    }
                } else if (binaryExpr.op.kind == TokenKind.MUL) {
                    if(leftExpr.literal.kind == INTEGER_LITERAL && rightExpr.literal.kind == INTEGER_LITERAL) {
                        var constant = Int64.parse(leftExpr.literal.value) * Int64.parse(rightExpr.literal.value)
                        return LitConstExpr(quote($(constant)))
                    } else {
                        var constant = Float64.parse(leftExpr.literal.value) * Float64.parse(rightExpr.literal.value)
                        return LitConstExpr(quote($(constant)))
                    }
                } else if (binaryExpr.op.kind == TokenKind.DIV) {
                    var constant = Float64.parse(leftExpr.literal.value) / Float64.parse(rightExpr.literal.value)
                    return LitConstExpr(quote($(constant)))
                } else if (binaryExpr.op.kind == TokenKind.MOD) {
                    var int_constant = Int64.parse(leftExpr.literal.value) % Int64.parse(rightExpr.literal.value)
                    return LitConstExpr(quote($(int_constant)))
                }
                else {
                    // unexpected calculation mode
                    throw Exception("unknown calculation mode")
                }
            }

            if(leftExpr is LitConstExpr) {
                binaryExpr.leftExpr = (leftExpr as LitConstExpr).getOrThrow()
            }
            if(rightExpr is LitConstExpr) {
                binaryExpr.rightExpr = (rightExpr as LitConstExpr).getOrThrow()
            }
            return binaryExpr
        }
        return expr
    }

    /*
    在程序中根据路径查找定义，路径必须已经根据'.'划分为字符串数组。仅支持形如“函数名”、“类名”、“类名.函数名”的解析。
    */
    static func findDeclByPath(prog: Program, paths: Array<String>): Decl {
        func findDecl(decls: ArrayList<Decl>, path: String): Option<Decl> {
            for (decl in decls) {
                if (decl.identifier.toString() == path) {
                    return decl
                }
            }
            return None
        }
        
        if (paths.size > 2) {
            throw Exception("paths cannot be more than two elements")
        }
        let topPath: String = paths[0]
        let topDecl = findDecl(prog.decls, topPath) ?? throw Exception("cannot find top declaration")
        if (paths.size == 1) {
            return topDecl
        }
        let classDecl = topDecl as ClassDecl ?? throw Exception("top declaration is not a ClassDecl") 
        let subPath: String = paths[1]
        let subDecl = findDecl(classDecl.body.decls, subPath) ?? throw Exception("cannot find sub declaration")
        return subDecl
    }

    /*
    将路径根据“.”划分成字符串数组。
    */
    static func splitPath(path: String): Array<String> {
        return path.split(".", removeEmpty: true)
    }
}