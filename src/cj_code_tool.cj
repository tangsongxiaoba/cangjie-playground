package playground

import std.ast.*
import std.collection.*
import std.convert.*

class IllegalInputException <: Exception {
    public init() {
        super("ILLEGAL INPUT")
    }
    
    public open override func getClassName(): String {
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
        } catch (e: Exception) {
            throw e
        }
    }

    private static func refractorDecl(decl: Decl, oldName: String, newName: String): Unit {
        if (decl.identifier.toString() == oldName) {
            decl.identifier = Token(TokenKind.IDENTIFIER, newName)
        }
        if (decl is ClassDecl) {
            refractorClassDecl(decl, oldName, newName)
        } else if (decl is FuncDecl) {
            refractorFuncDecl(decl, oldName, newName)
        } else if (decl is VarDecl) {
            refractorVarDecl(decl, oldName, newName)
        } else {
            throw ASTException("ILLEGAL INPUT")
        }
    }

    // 类定义节点，包含类体、“&”、父类或父接口和“<:”
    private static func refractorClassDecl(decl: Decl, oldName: String, newName: String) {
        var classDecl = decl as ClassDecl
        match (classDecl) {
            case Some(classDecl) =>
                for (superType in classDecl.superTypes) {
                    refractorTypeNode(superType, oldName, newName)
                }
                refractorBody(classDecl.body, oldName, newName)
            case None =>    
                throw ASTException("decl is not a classDecl")
        }
    }

    // 类体节点，包含声明节点集合和左右大括号
    private static func refractorBody(node: Node, oldName: String, newName: String) {
        var body = node as Body
        match (body) {
            case Some(body) =>
                for (decl in body.decls) {
                    refractorDecl(decl, oldName, newName)
                }
            case None =>
                throw ASTException("node is not a body")
        }
    }

    // 函数定义节点，包含函数体、冒号、返回类型、参数、左右小括号和重载操作符
    private static func refractorFuncDecl(decl: Decl, oldName: String, newName: String) {
        var funcDecl = decl as FuncDecl
        match (funcDecl) {
            case Some(funcDecl) =>
                for (p in funcDecl.funcParams) {
                    if (p.identifier.toString() == oldName) {
                        p.identifier = Token(TokenKind.IDENTIFIER, newName)
                    }
                }
                refractorBlock(funcDecl.block, oldName, newName)
            case None =>
                throw ASTException("decl is not a funcDecl")
        }
    }

    // 变量定义节点，包含赋值操作符位置信息、冒号位置信息、变量类型、初始化节点、pattern节点
    private static func refractorVarDecl(decl: Decl, oldName: String, newName: String) {
        var varDecl = decl as VarDecl
        match (varDecl) {
            case Some(varDecl) =>
                try {
                    refractorExpr(varDecl.expr, oldName, newName) // expr can be null
                } catch (e: ASTException) {}
                try {
                    refractorPattern(varDecl.pattern, oldName, newName) // pattern can be null
                } catch (e: ASTException) {}
            case None =>
                throw ASTException("decl is not a varDecl")
        }
    }

    // 仓颉语法树节点的父类
    private static func refractorNode(node: Node, oldName: String, newName: String) {
        if (node is Expr) {
            refractorExpr(node, oldName, newName)
        } else if (node is Decl) {
            refractorDecl(node, oldName, newName)
        } else if (node is Body) {
            refractorBody(node, oldName, newName)
        } else if (node is ImportContent) {
            refractorImportContent(node, oldName, newName)
        } else if (node is ImportList) {
            refractorImportList(node, oldName, newName)
        } else if (node is Modifier) {
            refractorModifier(node, oldName, newName)
        } else if (node is PackageHeader) {
            refractorPackageHeader(node, oldName, newName)
        } else if (node is Pattern) {
            refractorPattern(node, oldName, newName)
        } else if (node is TypeNode) {
            refractorTypeNode(node, oldName, newName)
        } else {
            throw Exception("node is unknown")
        }          
    }

    // 表达式节点的父类
    private static func refractorExpr(node: Node, oldName: String, newName: String): Unit{
        var expr = node as Expr
        match (expr) {
            case Some(expr) =>
                if (expr is AssignExpr) {
                    refractorAssignExpr(expr, oldName, newName)
                } else if (expr is BinaryExpr) {
                    refractorBinaryExpr(expr, oldName, newName)
                } else if (expr is Block) {
                    refractorBinaryExpr(expr, oldName, newName)
                } else if (expr is ForInExpr) {
                    refractorForInExpr(expr, oldName, newName)
                } else if (expr is IfExpr) {
                    refractorIfExpr(expr, oldName, newName)
                } else if (expr is LitConstExpr) {
                    refractorLitConstExpr(expr, oldName, newName)
                } else if (expr is ParenExpr) {
                    refractorParenExpr(expr, oldName, newName)
                } else if (expr is RangeExpr) {
                    refractorRangeExpr(expr, oldName, newName)
                } else if (expr is RefExpr) {
                    refractorRefExpr(expr, oldName, newName)
                } else if (expr is ReturnExpr) {
                    refractorReturnExpr(expr, oldName, newName)
                } else if (expr is UnaryExpr) {
                    refractorUnaryExpr(expr, oldName, newName)
                } else {  
                    throw Exception("expr is unknown")
                }
            case None =>
                throw ASTException("node is not an expr")
        }
    }

    // 导入包节点，包含导入类型、完整包名的前缀部分、“.”、被导入的项、导入的定义或声明的别名词法单元序列、左右大括号、所有被导入的项、“,”
    private static func refractorImportContent(node: Node, oldName: String, newName: String) {
        // do nothing：不在作用域内
    }

    // 包导入节点，包含修饰符、import关键字和导入的具体项
    private static func refractorImportList(node: Node, oldName: String, newName: String) {
        // do nothing：不在作用域内
    }

    // 修饰符节点，包含关键字
    private static func refractorModifier(node: Node, oldName: String, newName: String) {
        // do nothing：修饰符不替换
    }

    // 包声明节点，包含访问性修饰符、macro关键字、package关键字、完整包名的前缀部分、“.”、包名
    private static func refractorPackageHeader(node: Node, oldName: String, newName: String) {
        // do nothing：不在作用域内
    }

    // 模式匹配节点的父类
    private static func refractorPattern(node: Node, oldName: String, newName: String) {
        var pattern = node as Pattern ?? throw Exception("unknown")
        if (pattern is VarPattern) {
            refractorVarPattern(node, oldName, newName)
        } else {
            println(pattern.toTokens().toString())
            throw Exception("pattern is unknown")
        }
    }

    // 绑定模式节点，包含标识符
    private static func refractorVarPattern(node: Node, oldName: String, newName: String) {
        var varPattern = node as VarPattern
        match (varPattern) {
            case Some(varPattern) =>
                if (varPattern.identifier.toString() == oldName) {
                    varPattern.identifier = Token(TokenKind.IDENTIFIER, newName)
                }
            case None =>
                throw ASTException("node is not an varPattern")
        }
    }

    // 类型节点的父类，包含类型节点的参数，“:”
    private static func refractorTypeNode(node: Node, oldName: String, newName: String): Unit {
        var typeNode = node as TypeNode
        match (typeNode) {
            case Some(typeNode) =>
                if (typeNode.typeParameterName.toString() == oldName) {
                    typeNode.typeParameterName = Token(TokenKind.IDENTIFIER, newName)
                }
                if (typeNode is PrimitiveType) {
                    refractorPrimitiveType(typeNode, oldName, newName)
                } else if (typeNode is RefType) {
                    refractorRefType(typeNode, oldName, newName)
                } else {
                    throw Exception("typeNode is unknown")
                }
            case None =>
                throw ASTException("node is not an typeNode")
        }
    }

    // 基本类型节点，包含关键字
    private static func refractorPrimitiveType(typeNode: TypeNode, oldName: String, newName: String) {
        // do nothing：关键字不替换
    }

    // 非基础类型节点，包含“,”、关键字、左右尖括号、实例化类型列表
    private static func refractorRefType(typeNode: TypeNode, oldName: String, newName: String) {
        var refType = typeNode as RefType
        match (refType) {
            case Some(refType) =>
                for (t in refType.typeArguments) {
                    refractorTypeNode(t, oldName, newName)
                }
            case None =>
                throw ASTException("node is not an refType")
        }
    }

    // 赋值表达式节点，包含左操作数、右操作数和操作符
    private static func refractorAssignExpr(expr: Expr, oldName: String, newName: String) {
        var assignExpr = expr as AssignExpr
        match (assignExpr) {
            case Some(assignExpr) =>
                refractorExpr(assignExpr.leftExpr, oldName, newName)
                refractorExpr(assignExpr.rightExpr, oldName, newName)
            case None =>
                throw ASTException("node is not an assignExpr")
        }
    }

    // 二元操作表达式节点，包含左操作数、右操作数和操作符
    private static func refractorBinaryExpr(expr: Expr, oldName: String, newName: String) {
        var binaryExpr = expr as BinaryExpr
        match (binaryExpr) {
            case Some(binaryExpr) =>
                refractorExpr(binaryExpr.leftExpr, oldName, newName)
                refractorExpr(binaryExpr.rightExpr, oldName, newName)
            case None =>
                throw ASTException("node is not an binaryExpr")
        }
    }

    // 块节点，包含左大括号、右大括号和块内表达式或声明序列
    private static func refractorBlock(expr: Expr, oldName: String, newName: String) {
        var block = expr as Block
        match (block) {
            case Some(block) =>
                for (node in block.nodes) {
                    refractorNode(node, oldName, newName)
                }
            case None =>
                throw ASTException("node is not an block")
        }
    }

    // for-in表达式节点，包含循环体、表达式、for关键字、in关键字、where关键字、for的左右小括号、pattern节点、patternGuard条件表达式
    private static func refractorForInExpr(expr: Expr, oldName: String, newName: String) {
        var forInExpr = expr as ForInExpr
        match (forInExpr) {
            case Some(forInExpr) =>
                refractorBlock(forInExpr.block, oldName, newName)
                refractorExpr(forInExpr.expr, oldName, newName)
                refractorPattern(forInExpr.pattern, oldName, newName)
            case None =>
                throw ASTException("node is not an forInExpr")
        }
    }

    // 条件表达式节点，包含if后的条件表达式、else后的分支节点、if后的block节点、if和else关键字、if的左右小括号
    private static func refractorIfExpr(expr: Expr, oldName: String, newName: String) {
        var ifExpr = expr as IfExpr
        match (ifExpr) {
            case Some(ifExpr) =>
                refractorExpr(ifExpr.condition, oldName, newName)
                refractorExpr(ifExpr.elseExpr, oldName, newName)
                refractorBlock(ifExpr.ifBlock, oldName, newName)
            case None =>
                throw ASTException("node is not an ifExpr")
        }
    }

    // 常量表达式节点，包含字面量
    private static func refractorLitConstExpr(expr: Expr, oldName: String, newName: String) {
        // do nothing: "abc", 123 等递归最小单元，无需替换
    }

    // 括号表达式节点，包含左右小括号和括号内的子表达式
    private static func refractorParenExpr(expr: Expr, oldName: String, newName: String) {
        var parenExpr = expr as ParenExpr
        match (parenExpr) {
            case Some(parenExpr) =>
                refractorExpr(parenExpr.parenthesizedExpr, oldName, newName)
            case None =>
                throw ASTException("node is not an parenExpr")
        }
    }

    // 包含区间操作符的表达式节点，包含“:”操作符、终止值、起始值、Range操作符“..”“..=”、序列前后两个元素的差值
    private static func refractorRangeExpr(expr: Expr, oldName: String, newName: String) {
        var rangeExpr = expr as RangeExpr
        match (rangeExpr) {
            case Some(rangeExpr) =>
                try {
                    refractorExpr(rangeExpr.start, oldName, newName) // start can be null
                } catch (e: ASTException) {}
                try {
                    refractorExpr(rangeExpr.end, oldName, newName) // end can be null
                } catch (e: ASTException) {}
                try {
                    refractorExpr(rangeExpr.step, oldName, newName) // step can be null
                } catch (e: ASTException) {}
            case None =>
                throw ASTException("node is not an rangeExpr")
        }
    }

    // 声明的表达式节点，包含“,”词法单元序列，标识符，左右尖括号，实例化类型
    private static func refractorRefExpr(expr: Expr, oldName: String, newName: String) {
        var refExpr = expr as RefExpr
        match (refExpr) {
            case Some(refExpr) =>
                if (refExpr.identifier.toString() == oldName) {
                    refExpr.identifier = Token(TokenKind.IDENTIFIER, newName)
                }
                for (t in refExpr.typeArguments) {
                    refractorTypeNode(t, oldName, newName)
                }
            case None =>
                throw ASTException("node is not an refExpr")
        }
    }

    // return表达式节点，包含return关键字和表达式
    private static func refractorReturnExpr(expr: Expr, oldName: String, newName: String) {
        var returnExpr = expr as ReturnExpr
        match (returnExpr) {
            case Some(returnExpr) =>
                try {
                    refractorExpr(returnExpr.expr, oldName, newName) // expr can be null
                } catch (e: ASTException) {}
            case None =>
                throw ASTException("node is not an returnExpr")
        }
    }

    // 一元操作表达式节点，包含一元操作符、操作数
    private static func refractorUnaryExpr(expr: Expr, oldName: String, newName: String) {
        var unaryExpr = expr as UnaryExpr
        match (unaryExpr) {
            case Some(unaryExpr) =>
                refractorExpr(unaryExpr.expr, oldName, newName)
            case None =>
                throw ASTException("node is not an unaryExpr")
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
        func getPreLine(index: Int64, tokens: Tokens) : Int32 {
            var preIndex = index - 1
            while(tokens.get(preIndex).kind == TokenKind.NL) {
                preIndex--
            }
            return tokens.get(preIndex).pos.line
        }
        func getDoc(code: String) : String {
            let robot = LLM(url: 'https://api.siliconflow.cn/v1/chat/completions',
                key: 'sk-pqwthdmbesdwldfllezgjildshqhezpwzjbupqolzijkxjoa',
                model: 'deepseek-ai/DeepSeek-V3',
                context: true)
            return robot.chat(code)
        }

        try{
            var program = code.toProgram()
            var programTokens = program.toTokens()
            var decl = findDeclByPath(program, splitPath(path))
            
            let col = decl.toTokens().get(0).pos.column
            let line = decl.toTokens().get(0).pos.line
            let index : Int64 = getIndex(programTokens, decl) ?? throw Exception("cannot get index of decl")
            let preline = getPreLine(index, programTokens)

            var retBuilder = StringBuilder()
            for(i in 1..line-preline) {
                retBuilder.append('\n')
            }

            var strDecl = decl.toTokens().toString()
            let ret = getDoc(strDecl)
            retBuilder.append(addSpace(col, '/*'))
            retBuilder.append(addSpace(col, ret))
            retBuilder.append(addSpace(col, '*/'))

            return programTokens.insert(index, cangjieLex(retBuilder.toString())).toString()
        } catch(e: Exception) {
            return "ILLEGAL INPUT"
        }
        
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
            throw IllegalInputException()
        }
        let topPath: String = paths[0]
        let topDecl = findDecl(prog.decls, topPath) ?? throw IllegalInputException()
        if (paths.size == 1) {
            return topDecl
        }
        let classDecl = topDecl as ClassDecl ?? throw throw IllegalInputException()
        let subPath: String = paths[1]
        let subDecl = findDecl(classDecl.body.decls, subPath) ?? throw throw IllegalInputException()
        return subDecl
    }

    /*
    将路径根据“.”划分成字符串数组。
    */
    static func splitPath(path: String): Array<String> {
        return path.split(".", removeEmpty: true)
    }
}