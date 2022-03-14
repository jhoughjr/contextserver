import Vapor

func encode<T: Codable>(_ o: T) -> String  {
    
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .millisecondsSince1970
    encoder.outputFormatting = [.prettyPrinted]
    if let encoded = try? encoder.encode(o),
       let jsonString = String(data: encoded, encoding: .utf8) {
        return jsonString
    }else {
        return "\(o)"
    }
}

func routes(_ app: Application) throws {
    
    // RESTish Interface
   
    app.get("leaf", "engine") { req in
        req.view.render("engine", ContextEngine.shared.state())
    }
    
    app.get("engine") { req -> String in
        encode(ContextEngine.shared.state())
    }
    
    app.get("currentObservation") { req -> String in
        encode(ContextEngine.shared.currentObservation())
    }
    
    app.get("probeHistory") { req -> String in
        encode(ContextEngine.shared.probeHistory)
    }
    
    app.get("observationHistory") { req -> String in
        encode(ContextEngine.shared.observationHistory)
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
        ws.send( encode(ContextEngine.shared.currentObservation()) )
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
