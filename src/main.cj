package playground

import std.fs.File
import std.io.StringReader
import net.http.*
import encoding.json.*

func sendJsonResponse(res: HttpResponseBuilder, statusCode: UInt16, data: JsonValue) {
    let headers = HttpHeaders()
    headers.add("Content-Type", "application/json;charset=utf-8")
    headers.add("Access-Control-Allow-Origin", "*")
    res.setHeaders(headers)
    res.status(statusCode)
    res.body(data.toJsonString())
}

func sendSuccessResponse(res: HttpResponseBuilder, dataPayload: JsonObject) {
    let response = JsonObject()
    response.put("success", JsonBool(true))
    response.put("data", dataPayload)
    sendJsonResponse(res, 200, response)
}

func sendErrorResponse(res: HttpResponseBuilder, errorMessage: String, statusCode: UInt16, errorDetails: Option<JsonObject>) {
    let response = JsonObject()
    response.put("success", JsonBool(false))
    response.put("error", JsonString(errorMessage))
    match (errorDetails) {
        case Some(details) => let errorDataPayload = JsonObject()
                              errorDataPayload.put("details", details)
                              response.put("data", errorDataPayload)
        case None => ()
    }
    sendJsonResponse(res, statusCode, response)
}

func sendCorsPreflightResponse(res: HttpResponseBuilder) {
    let headers = HttpHeaders()
    headers.add("Access-Control-Allow-Origin", "*")
    headers.add("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
    headers.add("Access-Control-Allow-Headers", "Content-Type, Authorization")
    headers.add("Access-Control-Max-Age", "86400")
    res.setHeaders(headers)
    res.status(204)
    res.body("")
}

main() {
    let server = HttpServer("0.0.0.0", 8080)

    server.route("/api/cj-tool/generate-signature", { req, res =>
        if (req.method == "POST") {
            try {
                let content = StringReader(req.body).readToEnd()
                let requestJson = JsonValue.fromStr(content).asObject()
                let code = requestJson.get("code").getOrThrow().asString().getValue()

                if (code.isEmpty()) {
                    sendErrorResponse(res, "Input code cannot be empty.", 400, None)
                    return
                }
                var signature: String
                try {
                    signature = CJCodeTool.generateCodeSignature(code)
                } catch (e: IllegalInputException) {
                    e.dump()
                    e.printStackTrace()
                    let details = JsonObject()
                    details.put("nodeInfo", JsonString(e.toString()))
                    sendErrorResponse(res, e.message, 400, details)
                    return
                } catch (e: Exception) {
                    e.printStackTrace()
                    sendErrorResponse(res, "Error occurred, check logs.", 500, None)
                    return
                }

                let data = JsonObject()
                data.put("signature", JsonString(signature))
                sendSuccessResponse(res, data)

            } catch (e: JsonException) {
                sendErrorResponse(res, "Invalid JSON request: " + e.message, 400, None)
            } catch (e: Exception) {
                sendErrorResponse(res, "Server error: " + e.message, 500, None)
            }
        } else if (req.method == "OPTIONS") {
            sendCorsPreflightResponse(res)
        } else {
            sendErrorResponse(res, "Method Not Allowed", 405, None)
        }
    })

    server.route("/api/cj-tool/refactor-variable", { req, res =>
        if (req.method == "POST") {
            try {
                let content = StringReader(req.body).readToEnd()
                let requestJson = JsonValue.fromStr(content).asObject()
                let code = requestJson.get("code").getOrThrow().asString().getValue()
                let path = requestJson.get("path").getOrThrow().asString().getValue()
                let oldName = requestJson.get("oldName").getOrThrow().asString().getValue()
                let newName = requestJson.get("newName").getOrThrow().asString().getValue()

                if (code.isEmpty() || path.isEmpty() || oldName.isEmpty() || newName.isEmpty()) {
                    sendErrorResponse(res, "Missing required fields (code, path, oldName, newName).", 400, None)
                    return
                }

                var refactoredCode: String
                try {
                    refactoredCode = CJCodeTool.refractorVariable(code, path, oldName, newName)
                } catch (e: IllegalInputException) {
                    e.dump()
                    e.printStackTrace()
                    let details = JsonObject()
                    details.put("nodeInfo", JsonString(e.toString()))
                    sendErrorResponse(res, e.message, 400, details)
                    return
                } catch (e: Exception) {
                    e.printStackTrace()
                    sendErrorResponse(res, "Error occurred, check logs.", 500, None)
                    return
                }
                
                let data = JsonObject()
                data.put("refactoredCode", JsonString(refactoredCode))
                sendSuccessResponse(res, data)

            } catch (e: JsonException) {
                sendErrorResponse(res, "Invalid JSON request: " + e.message, 400, None)
            } catch (e: Exception) {
                sendErrorResponse(res, "Server error: " + e.message, 500, None)
            }
        } else if (req.method == "OPTIONS") {
            println("[LOG] Handling general OPTIONS request for: " + req.toString())
            sendCorsPreflightResponse(res)
        } else {
            sendErrorResponse(res, "Method Not Allowed", 405, None)
        }
    })

    server.route("/api/cj-tool/generate-document", { req, res =>
        if (req.method == "POST") {
            try {
                let content = StringReader(req.body).readToEnd()
                let requestJson = JsonValue.fromStr(content).asObject()
                let code = requestJson.get("code").getOrThrow().asString().getValue()
                let path = requestJson.get("path").getOrThrow().asString().getValue()
                let apiKey = requestJson.get("apiKey").getOrThrow().asString().getValue()
                let apiUrl = requestJson.get("apiUrl").getOrThrow().asString().getValue()
                let modelName = requestJson.get("modelName").getOrThrow().asString().getValue()
                
                CJCodeTool.configureLLM(apiUrl, apiKey, modelName)

                if (code.isEmpty() || path.isEmpty()) {
                    sendErrorResponse(res, "Missing required fields (code, path).", 400, None)
                    return
                }
                
                var documentedCode: String
                try {
                    documentedCode = CJCodeTool.generateDocument(code, path)
                } catch (e: IllegalInputException) {
                    e.dump()
                    e.printStackTrace()
                    let details = JsonObject()
                    details.put("nodeInfo", JsonString(e.toString()))
                    sendErrorResponse(res, e.message, 400, details)
                    return
                } catch (e: Exception) {
                    e.printStackTrace()
                    sendErrorResponse(res, "Error occurred, check logs.", 500, None)
                    return
                }
                
                let data = JsonObject()
                data.put("documentedCode", JsonString(documentedCode))
                sendSuccessResponse(res, data)

            } catch (e: JsonException) {
                sendErrorResponse(res, "Invalid JSON request: " + e.message, 400, None)
            } catch (e: Exception) {
                sendErrorResponse(res, "Server error: " + e.message, 500, None)
            }
        } else if (req.method == "OPTIONS") {
            sendCorsPreflightResponse(res)
        } else {
            sendErrorResponse(res, "Method Not Allowed", 405, None)
        }
    })

    server.route("/api/cj-tool/fold-constant", { req, res =>
        if (req.method == "POST") {
            try {
                let content = StringReader(req.body).readToEnd()
                let requestJson = JsonValue.fromStr(content).asObject()
                let code = requestJson.get("code").getOrThrow().asString().getValue()

                if (code.isEmpty()) {
                    sendErrorResponse(res, "Input code cannot be empty.", 400, None)
                    return
                }

                var foldedCode: String
                try {
                    foldedCode = CJCodeTool.foldConstant(code)
                } catch (e: IllegalInputException) {
                    e.dump()
                    e.printStackTrace()
                    let details = JsonObject()
                    details.put("nodeInfo", JsonString(e.toString()))
                    sendErrorResponse(res, e.message, 400, details)
                    return
                } catch (e: Exception) {
                    e.printStackTrace()
                    sendErrorResponse(res, "Error occurred, check logs.", 500, None)
                    return
                }

                let data = JsonObject()
                data.put("foldedCode", JsonString(foldedCode))
                sendSuccessResponse(res, data)

            } catch (e: JsonException) {
                sendErrorResponse(res, "Invalid JSON request: " + e.message, 400, None)
            } catch (e: Exception) {
                sendErrorResponse(res, "Server error: " + e.message, 500, None)
            }
        } else if (req.method == "OPTIONS") {
            println("[LOG] Handling general OPTIONS request for: " + req.toString())
            sendCorsPreflightResponse(res)
        } else {
            sendErrorResponse(res, "Method Not Allowed", 405, None)
        }
    })

    server.route("/api/cj-tool/find-unused-variables", { req, res =>
        if (req.method == "POST") {
            try {
                let content = StringReader(req.body).readToEnd()
                let requestJson = JsonValue.fromStr(content).asObject()
                let code = requestJson.get("code").getOrThrow().asString().getValue()

                if (code.isEmpty()) {
                    sendErrorResponse(res, "Input code cannot be empty.", 400, None)
                    return
                }

                var modifiedCode: String
                try {
                    modifiedCode = CJCodeTool.findUnusedVariables(code)
                } catch (e: IllegalInputException) {
                    e.dump()
                    e.printStackTrace()
                    let details = JsonObject()
                    details.put("nodeInfo", JsonString(e.toString()))
                    sendErrorResponse(res, e.message, 400, details)
                    return
                } catch (e: Exception) {
                    e.printStackTrace()
                    sendErrorResponse(res, "Error occurred, check logs.", 500, None)
                    return
                }

                let data = JsonObject()
                data.put("modifiedCode", JsonString(modifiedCode))
                sendSuccessResponse(res, data)

            } catch (e: JsonException) {
                sendErrorResponse(res, "Invalid JSON request: " + e.message, 400, None)
            } catch (e: Exception) {
                sendErrorResponse(res, "Server error: " + e.message, 500, None)
            }
        } else if (req.method == "OPTIONS") {
            sendCorsPreflightResponse(res)
        } else {
            sendErrorResponse(res, "Method Not Allowed", 405, None)
        }
    })

    server.start()
}