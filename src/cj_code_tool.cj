package playground

import std.ast.*

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
        // TODO
        return code
    }

    static func foldConstant(code: String): String {
        // TODO
        return code
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