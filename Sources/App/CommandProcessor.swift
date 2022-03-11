//
//  File.swift
//  
//
//  Created by Jimmy on 3/11/22.
//

import Foundation
import Vapor

enum Commands:String, Codable, CaseIterable {
    case help
    case who
    case whoami
    
    func execute() -> String {
        "OK"
    }
}

class CommandProcessor {
    static let shared = CommandProcessor()
    
    func handleCommand(commandString:String,
                       for ws:WebSocket ) {
        
        if let command = Commands.allCases.first(where: { co in
           return  co.rawValue == commandString.lowercased()
        }) {
            ws.send("'\(command)' executing...")
            ws.send("\(command.execute())")
        }else {
            ws.send("'\(commandString)' is not a command.")
        }
    }
}
