package playground

import std.ast.*
import std.collection.*
import std.convert.*

class CJCodeTool {
    static func generateCodeSignature(code: String): String {
        // TODO
        return code
    }

    static func refractorVariable(code: String, path: String, oldName: String, newName: String): String {
        // TODO        
        return code
    }

    static func generateDocument(code: String, path: String): String {
        func addSpace(n: Int32, str: String) : StringBuilder {
            var tempBuilder = StringBuilder()
            for(i in 1..n) {
                tempBuilder.append(' ')
            }
            tempBuilder.append(str)
            tempBuilder.append('\n')
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
        // TODO
        var program = code.toProgram()
        var programTokens = program.toTokens()
        var decl = findDeclByPath(program, splitPath(path))
        var strDecl = decl.toTokens().toString()
        let col = decl.toTokens().get(0).pos.column
        let line = decl.toTokens().get(0).pos.line
        let ret = getDoc(strDecl)
        // let ret = "ret"
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
        var program = str.toProgram()
        program.dump()
        for(decl in program.decls) {
            foldConstForDecl(decl)
        }
        return program.toString()
    }

    /*
    对定义进行折叠常量处理
    */
    private static func foldConstForDecl(decl: Decl): Unit {
        if (decl is VarDecl) {
            var ndecl = (decl as VarDecl).getOrThrow()
            try {
                ndecl.expr = foldConstForExpr(ndecl.expr)
            } catch (e: ASTException) {
                return
            }
        }
        else if (decl is FuncDecl) {
            var ndecl = (decl as FuncDecl).getOrThrow()
            foldConstForBlock(ndecl.block)
        } else if (decl is ClassDecl) {
            var ndecl = (decl as ClassDecl).getOrThrow()
            for(ddecl in ndecl.body.decls) {
                foldConstForDecl(ddecl)
            }
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
        }
    }

    /*
    对表达式进行折叠常量处理
    */
    static func foldConstForExpr(expr: Expr) : Expr {
        if (expr is BinaryExpr) {
            var binary_expr = (expr as BinaryExpr).getOrThrow()
            binary_expr.leftExpr = foldConstForExpr(binary_expr.leftExpr)
            binary_expr.rightExpr = foldConstForExpr(binary_expr.rightExpr)
            return calExpr(binary_expr)
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
        } else if (expr is ParenExpr) {
            var paren_expr = (expr as ParenExpr).getOrThrow()
            paren_expr.parenthesizedExpr = foldConstForExpr(paren_expr.parenthesizedExpr)
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
                    // ILLEGAL INPUT
                    return expr
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