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
    case setScriptSource
    case startEngine
    case stopEngine
    
    func execute() -> String {
        
        switch self {
        case .help:
        return """
            Commands are:
            help
            setScriptSource
            startEngine
            stopEngine
        Command?
            
        """
        case .setScriptSource:
            return "nop"
        case .startEngine:
            ContextEngine.shared.start()
            return "started"
        case .stopEngine:
            ContextEngine.shared.stop()
            return "stopped"
        default:
            return "unknown commamd"
            
        }
    }
}

class CommandProcessor {
    static let shared = CommandProcessor()
    
    func handleCommand(commandString:String,
                       for ws:WebSocket ) {
        
        if let command = Commands.allCases.first(where: { co in
           return  co.rawValue == commandString
        }) {
            ws.send("'\(command)' executing...")
            ws.send("\(command.execute())")
        }else {
            ws.send("'\(commandString)' is not a command.")
        }
    }
}
