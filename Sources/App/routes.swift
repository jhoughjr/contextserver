import Vapor

func routes(_ app: Application) throws {
    
    app.get("connectedClients") { req in
        return "\(ClientMonitor.shared.contextClients.count)"
    }
    
    app.webSocket("context") { req, ws in
        app.logger.info("\(String(describing: req.remoteAddress)) connected to context channel")
        
        if !ClientMonitor.shared.contextClients.contains(where: { connection in
            return connection.request.remoteAddress == req.remoteAddress
        }) {
            let connection = ClientMonitor.ClientConnection(request: req, socket: ws)
            ClientMonitor.shared.contextClients.append(connection)
        }
    }
    
    app.webSocket("command") { req, ws in
        
        app.logger.info("\(String(describing: req.remoteAddress)) connected to command channel")
        
        // sholdnt do this, as the same address will maybe sub to multiple channels
        
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
