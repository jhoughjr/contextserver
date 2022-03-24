//
//  File.swift
//  
//
//  Created by Jimmy on 3/23/22.
//

import Foundation
import Vapor

enum APIType:Content {
    case webSocket
    case rest
}

struct APISpec:Content {
    let bundleID:String
    let host:String
    let port:Int
    let probeEndpoint:String
    let type:APIType
}

class EngineTimer {
    static let shared = EngineTimer(nil)
    var vaporApp:Vapor.Application?
    
    var appTimes = [String:Double]()
    
    var timedApp = "" {
        didSet {
            timeApp()
        }
    }

    var timer:Timer?
    
    func timeApp() {
        vaporApp?.logger.debug("timing \(timedApp)")

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1,
                                     repeats: true) { t in
            if let t = self.appTimes[self.timedApp] {
                self.appTimes[self.timedApp] = t + 1
            }else {
                self.appTimes[self.timedApp] = 1
            }
            
        }
    }

    init(_ app:Vapor.Application?) {
        vaporApp = app
        vaporApp?.logger.notice("Engine Timer Started.")
    }
}
