package playground

import net.http.*

class HttpServer {
    let server: Server
    
    public init(ip: String, port: UInt16) {
        server = ServerBuilder().addr(ip).port(port).build()
        println("starting server on http://${ip}:${port}")
    }

    public func route(route: String,
        callback: (req: HttpRequest, res: HttpResponseBuilder) -> Unit) {
        server.distributor.register(route, { context => 
            callback(context.request, context.responseBuilder)
        })
    }

    public func start() {
        server.serve()
    }
}