import Vapor

func routes(_ app: Application) throws {
    
    // RESTish Interface
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]

    app.get("") { req in
        return "Welcome."
    }
    
    app.get("engine") { req -> String in
        let state = ContextEngine.shared.state()
        if let encoded = try? encoder.encode(state),
           let jsonString = String(data: encoded, encoding: .utf8) {
            return jsonString
        }else {
            return "\(state)"
        }
    }
    
    app.get("currentObservation") { req -> String in
        
        let current = ContextEngine.shared.currentObservation()
        if let encoded = try? encoder.encode(current),
           let jsonString = String(data: encoded, encoding: .utf8) {
            return jsonString
        }else {
            return "\(current)"
        }
    }
    
    app.get("probeHistory") { req -> String in
        let history = ContextEngine.shared.probeHistory
        if let encoded = try? encoder.encode(history),
           let jsonString = String(data: encoded, encoding: .utf8) {
            return jsonString
        }else {
            return "\(history)"
        }
    }
    
    app.get("observationHistory") { req -> String in
        let history = ContextEngine.shared.observationHistory
        if let encoded = try? encoder.encode(history),
           let jsonString = String(data: encoded, encoding: .utf8) {
            return jsonString
        }else {
            return "\(history)"
        }
    }
    
    // Websocket Interface
    app.webSocket("context") { req, ws in
        app.logger.info("\(String(describing: req.remoteAddress)) connected to context channel")
        
        if !ClientMonitor.shared.contextClients.contains(where: { connection in
            return connection.request.remoteAddress == req.remoteAddress
        }) {
            let connection = ClientMonitor.ClientConnection(request: req, socket: ws)
            ClientMonitor.shared.contextClients.append(connection)
        }
    }
    
//    app.webSocket("command") { req, ws in
//
//        app.logger.info("\(String(describing: req.remoteAddress)) connected to command channel")
//
//        // sholdnt do this, as the same address will maybe sub to multiple channels
//
//        if !ClientMonitor.shared.commandClients.contains(where: { connection in
//            return connection.request.remoteAddress == req.remoteAddress
//        }) {
//            let connection = ClientMonitor.ClientConnection(request: req, socket: ws)
//            ClientMonitor.shared.commandClients.append(connection)
//            ws.onText { ws, string in
//                CommandProcessor.shared.handleCommand(commandString: string, for: ws)
//            }
//            ws.send("Command?")
//        }
//    }
}
