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
    case start
    case stop
    case ver
    case app
    case context
    case bye
    
    func execute() -> String {
        
        switch self {
            
        case .app:
            return ContextEngine.shared.currentObservation().app
        case .context:
            return ContextEngine.shared.currentObservation().ctx
        case .help:
            var list = ""
            for com in Commands.allCases {
                list.append(contentsOf: com.rawValue)
                if Commands.allCases.firstIndex(of: com) != Commands.allCases.firstIndex(of: Commands.allCases.last!) {
                    list.append("\n")
                }
            }
        return
        """
        Commands are:
        \(list)
        READY>
            
        """
        case .setScriptSource:
            return "nop"
        case .start:
            ContextEngine.shared.start()
            return "started"
        case .stop:
            ContextEngine.shared.stop()
            return "stopped"
        case .ver:
            return "1.0.0 build 1"
        case .bye:
            return ""
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
            if command == .bye {
                ws.send("bye!")
                _ = ws.close()
            }
        }else {
            ws.send("'\(commandString)' is not a command. client commands are open, clr, and bye." + Commands.help.execute())
        }
    }
}
