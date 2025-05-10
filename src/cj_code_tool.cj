package playground

import std.ast.*
import std.collection.*
import std.convert.*

let DEBUG = true

class CJCodeTool {
    /*
    为代码中所有的函数、类和接口生成签名
    */
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
                    signature += signClassDecl((decl as ClassDecl).getOrThrow())
                } else if (decl is InterfaceDecl) {
                    signature += signInterfaceDecl((decl as InterfaceDecl).getOrThrow())
                } else if (decl is FuncDecl) {
                    signature += signFuncDecl((decl as FuncDecl).getOrThrow())
                } else {
                    throw IllegalInputException(decl)
                }
            } catch (e: IllegalInputException) {
                if (DEBUG) {
                    e.dump()
                }
                return e.message
            } catch (e: Exception) {
                throw e
            }
            
            if (start < tks.size) {
                signature += Token(TokenKind.NL) // add "\n"
                signature += Token(TokenKind.NL)
            }
        }
        return signature.toString()
    }

    /*
    为类生成签名
    */
    private static func signClassDecl(classDecl: ClassDecl): Tokens {
        var signature = Tokens()
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
            signature += signBodyDecls(bodyDecls)
            signature += Token(TokenKind.NL)
            signature += body.rBrace
        }

        return signature
    }

    /*
    为接口生成签名
    */
    private static func signInterfaceDecl(interfaceDecl: InterfaceDecl): Tokens {
        var signature = Tokens()
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
            signature += signBodyDecls(bodyDecls)
            signature += Token(TokenKind.NL)
            signature += body.rBrace
        }
        return signature
    }

    /*
    为方法生成签名
    */
    private static func signFuncDecl(funcDecl: FuncDecl): Tokens {
        var signature = Tokens()
        signature += funcDecl.lParen
        let funcParams = funcDecl.funcParams // funcParams can be null
        if (funcParams.size > 0) {
            for (p in funcParams) {
                signature += p.toTokens()
            }
        }
        signature += funcDecl.rParen
        try {
            let declType = funcDecl.declType // declType can be null
            signature += funcDecl.colon
            signature += declType.toTokens()
        } catch (e: ASTException) {}
        return signature
    }

    /*
    为定义体内部的定义生成签名
    */
    private static func signBodyDecls(decls: ArrayList<Decl>): Tokens {
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
                signature += decl.keyword
            } else {
                signature += decl.keyword
                signature += decl.identifier
            }
            if (decl is VarDecl) {
                let varDecl = (decl as VarDecl).getOrThrow()
                try {
                    let declType = varDecl.declType // declType can be null
                    signature += varDecl.colon
                    signature += declType.toTokens()
                } catch (e: ASTException) {}
            } else if (decl is PropDecl) {
                let propDecl = (decl as PropDecl).getOrThrow()
                try {
                    let declType = propDecl.declType // declType can be null
                    signature += propDecl.colon
                    signature += declType.toTokens()
                } catch (e: ASTException) {}
            } else if (decl is FuncDecl) {
                signature += signFuncDecl((decl as FuncDecl).getOrThrow())
            } else {
                throw IllegalInputException(decl)
            }
        }
        return signature
    }

    /*
    重命名指定作用域中的标识符
    */
    static func refractorVariable(code: String, path: String, oldName: String, newName: String): String {
        try {
            var prog = code.toProgram()
            var decl = findDeclByPath(prog, splitPath(path))
            refractorDecl(decl, oldName, newName)
            return prog.toString()
        } catch (e: IllegalInputException) {
            if (DEBUG) {
                e.dump()
            }
            return e.message
        } catch (e: Exception) {
            throw e
        }
    }

    /*
    重命名指定标识符
    */
    private static func refractorIdentifier(oldToken: Token, oldValue: String, newValue: String): Token {
        if (oldToken.toString() == oldValue) {
            return Token(TokenKind.IDENTIFIER, newValue)
        }
        return oldToken
    }

    /*
    重命名定义中的标识符
    */
    private static func refractorDecl(decl: Decl, oldName: String, newName: String): Unit {
        decl.identifier = refractorIdentifier(decl.identifier, oldName, newName)
        if (decl is ClassDecl) {
            let classDecl = (decl as ClassDecl).getOrThrow()
            for (superType in classDecl.superTypes) {
                refractorTypeNode(superType, oldName, newName)
            }
            refractorBody(classDecl.body, oldName, newName)
        } else if (decl is FuncDecl) {
            let funcDecl = (decl as FuncDecl).getOrThrow()
            for (p in funcDecl.funcParams) {
                p.identifier = refractorIdentifier(p.identifier, oldName, newName)
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
        } else if (decl is InterfaceDecl) {
            let interfaceDecl = (decl as InterfaceDecl).getOrThrow()
            for (superType in interfaceDecl.superTypes) {
                refractorTypeNode(superType, oldName, newName)
            }
            refractorBody(interfaceDecl.body, oldName, newName)
        } else if (decl is PropDecl) {
            let propDecl = (decl as PropDecl).getOrThrow()
            propDecl.identifier = refractorIdentifier(propDecl.identifier, oldName, newName)
            try {
                refractorDecl(propDecl.setter, oldName, newName)
            } catch (e: ASTException) {}
            try {
                refractorDecl(propDecl.getter, oldName, newName)
            } catch (e: ASTException) {}
        } else {
            throw IllegalInputException(decl)
        }
    }

    /*
    重命名定义体中的标识符
    */
    private static func refractorBody(body: Body, oldName: String, newName: String) {
        for (decl in body.decls) {
            refractorDecl(decl, oldName, newName)
        }
    }

    /*
    重命名表达式中的标识符
    */
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
            refExpr.identifier = refractorIdentifier(refExpr.identifier, oldName, newName)
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
            throw IllegalInputException(expr)
        }
    }

    /*
    重命名模式中的标识符
    */
    private static func refractorPattern(pattern: Pattern, oldName: String, newName: String) {
        if (pattern is VarPattern) {
            let varPattern = (pattern as VarPattern).getOrThrow()
            varPattern.identifier = refractorIdentifier(varPattern.identifier, oldName, newName)
        } else {
            throw IllegalInputException(pattern)
        }
    }

    /*
    重命名类型节点中的标识符
    */
    private static func refractorTypeNode(typeNode: TypeNode, oldName: String, newName: String): Unit {
        typeNode.typeParameterName = refractorIdentifier(typeNode.typeParameterName, oldName, newName)
        if (typeNode is RefType) {
            let refType = (typeNode as RefType).getOrThrow()
            for (t in refType.typeArguments) {
                refractorTypeNode(t, oldName, newName)
            }
        } else if (typeNode is PrimitiveType) { 
            // do nothing
        } else {
            throw IllegalInputException(typeNode)
        }
    }

    /*
    重命名块中的标识符
    */
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
                throw IllegalInputException(block)
            }
        }
    }

    /*
    为类或函数生成注释文档
    */
    static func generateDocument(code: String, path: String): String {
        func addIndent(n: Int32, str: String) : StringBuilder {
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

        try{
            var progTokens = cangjieLex(code)
            var prog = parseProgram(progTokens)
            var decl = findDeclByPath(prog, splitPath(path))
            let col = decl.toTokens().get(0).pos.column
            let index : Int64 = getIndex(progTokens, decl).getOrThrow()
            var retBuilder = StringBuilder()
            var strDecl = decl.toTokens().toString()
            let ret = getDoc(strDecl)
            retBuilder.append(addIndent(col, ret))
            return cangjieLex(progTokens[0..index].toString() + retBuilder.toString() + progTokens[index..].toString()).toString()
        } catch(e: IllegalInputException) {
            if(DEBUG) {
                e.dump()
            }
            e.message
        } catch(e: Exception) {
            throw e
        }
    }

    /*
    折叠常量
    */
    static func foldConstant(str: String) : String {
        try {
            let prog = str.toProgram()
            for(decl in prog.decls) {
                foldConstForDecl(decl)
            }
            return prog.toString()
        } catch(e: IllegalInputException) {
            if (DEBUG) {
                e.dump()
            }
            return e.message
        } catch(e: Exception) {
            throw e
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
        } else if (decl is InterfaceDecl) {
            var ndecl = (decl as InterfaceDecl).getOrThrow()
            for (ddecl in ndecl.body.decls) {
                foldConstForDecl(ddecl)
            }
        } else if (decl is PropDecl) {
            var ndecl = (decl as PropDecl).getOrThrow()
            try {
                foldConstForDecl(ndecl.getter)
            } catch (e: ASTException) {}
            try {
                foldConstForDecl(ndecl.setter)
            } catch (e: ASTException) {}
        } else {
            throw IllegalInputException(decl)
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
            throw IllegalInputException(expr)
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
            throw IllegalInputException(prog)
        }
        let topPath: String = paths[0]
        let topDecl = findDecl(prog.decls, topPath) ?? throw IllegalInputException(prog)
        if (paths.size == 1) {
            return topDecl
        }
        let classDecl = topDecl as ClassDecl ?? throw IllegalInputException(prog)
        let subPath: String = paths[1]
        let subDecl = findDecl(classDecl.body.decls, subPath) ?? throw IllegalInputException(prog)
        return subDecl
    }

    /*
    将路径根据“.”划分成字符串数组。
    */
    static func splitPath(path: String): Array<String> {
        return path.split(".", removeEmpty: true)
    }

    static func findUnusedVariables(code: String) : String {
        func comment(token: Token, tokens: Tokens) : Tokens {
            for(i in 0..tokens.size) {
                tokens[i].dump()
                if(tokens[i].pos.line == token.pos.line) {
                    return tokens.insertBefore(i, cangjieLex('/* UNUSED VAR */'))
                }
            }
            return tokens
        }
        func addComment(variables: HashSet<MyToken>, tokens: Tokens) {
            var it = variables.iterator()
            var ntokens = tokens
            while (true) {
                var value = it.next()
                match (value) {
                    case Some(v) => ntokens = comment(v.getToken(), ntokens)
                    case None => break
                }
            }
            return ntokens
        }
        func findFunc(decl: Decl, tokens: Tokens) : Tokens {
            var progTokens = tokens
            if (decl is FuncDecl) {
                let variables = HashSet<MyToken>()
                var funct = (decl as FuncDecl).getOrThrow()
                findInBlock(funct.block, variables)
                progTokens = addComment(variables, progTokens)
            } else if (decl is ClassDecl) {
                let variables = HashSet<MyToken>()
                var cdecl = (decl as ClassDecl).getOrThrow()
                for (ddecl in cdecl.body.decls) {
                    progTokens = findFunc(ddecl, progTokens)
                }
                progTokens = addComment(variables, progTokens)
            } else if (decl is VarDecl) {/* ignore it*/}
            else {
                throw IllegalInputException(decl)
            }
            return progTokens
        }
        
        try {
            var progTokens = cangjieLex(code)
            var prog = parseProgram(progTokens)
            prog.dump()

            // let variables = HashSet<MyToken>()
            for(decl in prog.decls) {
                progTokens = findFunc(decl, progTokens)
            }

            return progTokens.toString()
        } catch(e: IllegalInputException) {
            if (DEBUG) {
                e.dump()
            }
            return e.message
        }
    }

    private static func findInDecl(decl: Decl, variables: HashSet<MyToken>) : Unit {
        if (decl is VarDecl) {
            // initial condition
            var vdecl = (decl as VarDecl).getOrThrow()
            variables.put(MyToken(vdecl.identifier))
            findInExpr(vdecl.expr, variables)
        }
        else if (decl is FuncDecl) {
            var funct = (decl as FuncDecl).getOrThrow()
            findInBlock(funct.block, variables)
        }
        else if (decl is ClassDecl) {
            var cdecl = (decl as ClassDecl).getOrThrow()
            for (ddecl in cdecl.body.decls) {
                findInDecl(ddecl, variables)
            }
        }
        else {
            throw IllegalInputException(decl)
        }
    }

    private static func findInBlock(block: Block, variables: HashSet<MyToken>) : Unit {
        for(node in block.nodes) {
            if(node is Expr) {
                var expr = (node as Expr).getOrThrow()
                findInExpr(expr, variables)
            }
            else if (node is Decl) {
                var decl = (node as Decl).getOrThrow()
                findInDecl(decl, variables)
            }
        }
    }

    private static func findInExpr(expr: Expr, variables: HashSet<MyToken>) : Unit {
        if(expr is RefExpr) {
            // base condition
            var variable = (expr as RefExpr).getOrThrow()
            if(variables.contains(MyToken(variable.identifier))) {
                variables.remove(MyToken(variable.identifier))
            }
        } else if(expr is AssignExpr) {
            var asexpr = (expr as AssignExpr).getOrThrow()
            findInExpr(asexpr.leftExpr, variables)
            findInExpr(asexpr.rightExpr, variables)
        } else if (expr is BinaryExpr) {
            var bexpr = (expr as BinaryExpr).getOrThrow()
            findInExpr(bexpr.leftExpr, variables)
            findInExpr(bexpr.rightExpr, variables)
        } else if (expr is ForInExpr) {
            var forexpr = (expr as ForInExpr).getOrThrow()
            findInBlock(forexpr.block, variables)
        } else if (expr is IfExpr) {
            var ifexpr = (expr as IfExpr).getOrThrow()
            findInExpr(ifexpr.condition, variables)
            try {
                findInExpr(ifexpr.elseExpr, variables)
            } catch (e: ASTException) {}
            findInBlock(ifexpr.ifBlock, variables)
        } else if (expr is ParenExpr) {
            var pexpr = (expr as ParenExpr).getOrThrow()
            findInExpr(pexpr.parenthesizedExpr, variables)
        } else if (expr is RangeExpr) {
            var rexpr = (expr as RangeExpr).getOrThrow()
            try{
                findInExpr(rexpr.start, variables)} catch (e: ASTException) {}
            try{
                findInExpr(rexpr.end, variables)
            } catch (e: ASTException) {}
            try{
                findInExpr(rexpr.step, variables)
            } catch (e: ASTException) {}
        } else if (expr is ReturnExpr) {
            var retexpr = (expr as ReturnExpr).getOrThrow()
            findInExpr(retexpr.expr, variables)
        } else if (expr is UnaryExpr) {
            var uexpr = (expr as UnaryExpr).getOrThrow()
            findInExpr(uexpr.expr, variables)
        } else if (expr is LitConstExpr) {}

        else {
            throw IllegalInputException(expr)
        }

    } 
}