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
        let request:Request
        let socket:WebSocket
    }
    
    static let shared = ClientMonitor()

    var contextClients = [ClientConnection]()
}
