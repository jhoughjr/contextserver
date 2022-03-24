//
//  File.swift
//  
//
//  Created by Jimmy on 3/11/22.
//

import Foundation
import Vapor

enum Commands:String, Codable, CaseIterable {
    case probe
    case help
    case setScriptSource
    case start
    case stop
    case ver
    case app
    case context
    case bye
    case history
    case routes
    
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
        case .probe:
            
            ContextEngine.shared.probeContext()
            return Commands.context.execute()
        case .history:
            return  App.encode(ContextEngine.shared.probeHistory.reversed())
        case .routes:
            return App.encode(
                ["routes":["json":["get":["engine",
                                                 "version",
                                                 "unhandledApps",
                                                 "settings",
                                                 "currentObservation",
                                                 "probeHistory",
                                                 "observationHistory"],
                                          "post":["setttings/validateScriptPath",
                                                  "settings/ignoredApps"]
                                         ],
                                  "leaf":["get":["welcome",
                                                 "settings",
                                                 "state",
                                                 "engine",
                                                 "history",
                                                 "websocketprompt"],
                                  "ws":["context","command"]
                                         ]
                                 ]
                       ]
                          )
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
            ws.send("'\(command)' executing...") // mark execution start
            if command == .help {
                ws.send(command.execute() + " * Client commands are open, clr, and bye")
            }
            ws.send("\(command.execute())") // send result
            // local commands arent enumerated, so check here for them
            // other local commands are captured in teh webui
            // seems scattered but makes sense in situ
            if command == .bye {
                ws.send("bye!")
                _ = ws.close()
            }
        }else {
            ws.send("'\(commandString)' is not a command. client commands are open, clr, and bye." + Commands.help.execute())
        }
    }
}
