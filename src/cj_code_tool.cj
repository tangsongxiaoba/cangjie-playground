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
        for(decl in program.decls) {
            if (decl is MainDecl) {
                var ndecl = (decl as MainDecl).getOrThrow()
                for(node in ndecl.block.nodes) {
                    procNode(node)
                }
            } else if (decl is FuncDecl) {
                var ndecl = (decl as FuncDecl).getOrThrow()
                for(node in ndecl.block.nodes) {
                    procNode(node)
                }
            } else if (decl is ClassDecl) {
                var ndecl = (decl as FuncDecl).getOrThrow()
                for(node in ndecl.block.nodes) {
                    procNode(node)
                }
            }
        }
        return program.toString()
    }

    /*
    处理block
    */
    static func procBlock(block : Block) {
        for(node in block.nodes) {
            procNode(node)
        }
    }

    /*
    处理node
    */
    static func procNode(node: Node) : Unit{
        if(node is VarDecl) {
            var var_decl = (node as VarDecl).getOrThrow()
            try {
                var_decl.expr = calExpr(var_decl.expr)
            } catch(e: ASTException) {
                return
            }
        } else if (node is AssignExpr) {
            var assign_expr = (node as AssignExpr).getOrThrow()
            assign_expr.rightExpr = calExpr(assign_expr.rightExpr)
        } else if (node is ForInExpr) {
            var for_in_expr = (node as ForInExpr).getOrThrow()
            procBlock(for_in_expr.block)
        } else if (node is WhileExpr) {
            var while_expr = (node as WhileExpr).getOrThrow()
            while_expr.condition = calExpr(while_expr.condition)
            procBlock(while_expr.block)
        } else if (node is IfExpr) {
            var if_expr = (node as IfExpr).getOrThrow()
            if_expr.condition = calExpr(if_expr.condition)
            try {
                if_expr.elseExpr = calExpr(if_expr.elseExpr)
            } catch (e: ASTException) {}
            procBlock(if_expr.ifBlock)
        }
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
            var leftExpr = calExpr(binaryExpr.leftExpr)
            var rightExpr = calExpr(binaryExpr.rightExpr)
            
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
        if(expr is ParenExpr) {
            var parenExpr = (expr as ParenExpr).getOrThrow()
            return calExpr(parenExpr.parenthesizedExpr)
        }
        if(expr is IfExpr) {
            var ifExpr = (expr as IfExpr).getOrThrow()
            procNode(ifExpr)
            return expr
        }
        if(expr is Block) {
            var block = (expr as Block).getOrThrow()
            procBlock(block)
            return expr
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

    static func splitPath(path: String): Array<String> {
        return path.split(".", removeEmpty: true)
    }
}