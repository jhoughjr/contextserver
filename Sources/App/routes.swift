import Vapor
import Foundation
import Network
import NIOTransportServices

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
    app.get("leaf", "websocketprompt") { req async throws -> View in
        return try await req.view.render("websocketprompt", ["title":"Websocket Command Prompt",
                                                    "date":Date().formatted(date: .complete,
                                                                            time: .complete)])
    }
    
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
    
    app.get("leaf","welcome") { req async throws -> View in
        let ctx = ContextEngine.shared.engineState
        return try await req.view.render("welcome",  ["title":"Welcome to Context Engine",
                                                      "build": Commands.ver.rawValue,
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
    
    app.get("json","version") { req -> String in
        encode(Commands.ver.execute())
    }
    
    app.post("json","settings","validateScriptPath") { req -> String in
        
        let validation = try req.content.decode(ScriptPathValidation.self)
        let res = try await ContextEngine.shared.isValidScriptPath(validation)
        if res.isValid == true {
            // should access storage to set new value
            UserDefaults.standard.set(validation.path, forKey: "scriptSourceLocation")
            UserDefaults.standard.synchronize()
            app.logger.info("set new script source path \(validation.path)")
        }
        let coded = encode(res)
        req.logger.debug("\(coded)")
        return coded
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
        ws.send(encode(ContextEngine.shared.currentObservation()) )
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
            ws.send("READY>")
        }
    }
}
