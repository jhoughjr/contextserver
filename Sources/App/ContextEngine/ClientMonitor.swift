//
//  File.swift
//  
//
//  Created by Jimmy on 3/10/22.
//

import Foundation
import Vapor

class ClientMonitor {
    
    struct ClientConnection {
        let request:Request // the request they connected with
        let socket:WebSocket // their websocket
    }
    
    static let shared = ClientMonitor()

    var contextClients = [ClientConnection]() // clients connected to context updates
    var commandClients = [ClientConnection]() // clients connected to command prompt
}
