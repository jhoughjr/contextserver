import Vapor
import Foundation

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
    
    // basic web admin interface
    app.get("leaf","engine") { req async throws -> View in
        let ctx = ContextEngine.shared.probeHistory.last
        return try await req.view.render("engine", ["title":"Engine Status",
                                                    "status" : encode(ctx),
                                                    "date":Date().formatted(date: .complete,
                                                                            time: .complete)])
    }
    
    app.get("leaf","history") { req async throws -> View in
        let ctx = ContextEngine.shared.probeHistory.sorted { a, b in
            a.timestamp > b.timestamp
        }
        
        return try await req.view.render("history", ["title":"Engine History",
                                                     "history" : encode(ctx),
                                                     "date":Date().formatted(date: .complete,
                                                                             time: .complete)])
    }
    
    app.get("leaf","state") { req async throws -> View in
        let ctx = ContextEngine.shared.engineState
        return try await req.view.render("state",  ["title":"Engine State",
                                                       "state" : encode(ctx),
                                                       "date":Date().formatted(date: .complete,
                                                                               time: .complete)])
    }
    app.get("leaf","settings") { req async throws -> View in
        let ctx = ContextEngine.shared.engineSettings
        return try await req.view.render("settings",  ["title":"Engine Settings",
                                                       "settings" : encode(ctx),
                                                       "date":Date().formatted(date: .complete,
                                                                               time: .complete)])
    }
    
    // JSON Interface
    app.get("json","") { req -> String in
        encode(["routes":["engine",
                          "currentObservation",
                          "probeHistory",
                          "observationHistory"]])
    }
    
    app.get("json","engine") { req -> String in
        encode(ContextEngine.shared.state())
    }
    
    app.get("json","currentObservation") { req -> String in
        encode(ContextEngine.shared.currentObservation())
    }
    
    app.get("json","probeHistory") { req -> String in
        encode(ContextEngine.shared.probeHistory)
    }
    
    app.get("json","observationHistory") { req -> String in
        encode(ContextEngine.shared.observationHistory)
    }
    
    // Websocket Interface
    app.webSocket("ws","context") { req, ws in
        app.logger.info("\(String(describing: req.remoteAddress)) connected to context channel")
        
        if !ClientMonitor.shared.contextClients.contains(where: { connection in
            return connection.request.remoteAddress == req.remoteAddress
        }) {
            let connection = ClientMonitor.ClientConnection(request: req, socket: ws)
            ClientMonitor.shared.contextClients.append(connection)
        }
        ws.send( encode(ContextEngine.shared.currentObservation()) )
    }
    
    app.webSocket("ws","command") { req, ws in

        app.logger.info("\(String(describing: req.remoteAddress)) connected to command channel")

        if !ClientMonitor.shared.commandClients.contains(where: { connection in
            return connection.request.remoteAddress == req.remoteAddress
        }) {
            
            let connection = ClientMonitor.ClientConnection(request: req, socket: ws)
            ClientMonitor.shared.commandClients.append(connection)
            
            ws.onText { ws, string in
                CommandProcessor.shared.handleCommand(commandString: string, for: ws)
            }
            ws.send("Command?")
        }
    }
}
