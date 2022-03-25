//
//  EngineTimer.swift
//  
//
//  Created by Jimmy on 3/23/22.
//

import Foundation
import Vapor
import BSON
import MongoKittenCore

struct TimeCollection:Content {
    var id:ObjectId
    var times:[String:Double]
}

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
    
    public enum UpdatePoint {
        case onSwitch // always updated on switch
        case immediately // updates on switch and every second
    }
    
    public static let shared = EngineTimer(nil)

    public var updatePoint:UpdatePoint = .onSwitch
    internal var vaporApp:Vapor.Application?
    
    public var appTimes = [String:Double]()
    
    public var timedApp = "" {
        willSet {
            Task {
                try await self.recordTime()
            }
          
        }
        didSet {
            timeApp()
        }
    }

    var mergeCount = 0
    
    func merge(times:[String:Double],
               with doc:Document) -> Document {
        
        vaporApp?.logger.info("merthing \(times) with \(doc)")
    
        mergeCount = mergeCount + 1
        var newTimes = Document()

        if mergeCount <= 2 {
            
        for appTime in times {
            if let previous = doc[appTime.key] as? Double {
                newTimes[appTime.key] = appTime.value + previous
            }else {
                newTimes[appTime.key] = appTime.value
            }
        }
        vaporApp?.logger.info("merged \(newTimes)")
        }
        return newTimes
    }
   
    private func recordTime() async throws {
        
        vaporApp?.logger.info("recording time")
        self.vaporApp?.logger.info("\(self.appTimes)")

        if let times = vaporApp?.mongoDB["times"] {
            
            if let oldtimes = try await times.findOne(["source":"me"]).get() {
                
                vaporApp?.logger.info("previous times in mongo")
                let merged = merge(times: self.appTimes,
                                   with: oldtimes)
                
                let res = try await times.upsert( merged,
                                                 where: ["source":"me"]).get()
                vaporApp?.logger.info("rep \(res)")
               
            }else {
                
                var newTimes = Document()
                newTimes["source"] = "me"
                
                let res = try await times.upsert( merge(times: self.appTimes,
                                                        with: newTimes),
                                                 where: ["source":"me"]).get()
                vaporApp?.logger.info("new \(res)")
            }
            
        }else {
            vaporApp?.logger.info("couldnt get times collection")
        }
    }
    
    private var timer:Timer?
    
    private func timeApp() {
        
        vaporApp?.logger.info("timing \(timedApp)")

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1,
                                     repeats: true) { t in
            
            if let t = self.appTimes[self.timedApp] {
                self.appTimes[self.timedApp] = t + 1
            }else {
                self.vaporApp?.logger.info("new time entry")
                self.appTimes[self.timedApp] = 1
            }
            
            if self.updatePoint == .immediately {
                Task {
                    try await self.recordTime()
                }
            }
        }
    }

    init(_ app:Vapor.Application?) {
        vaporApp = app
        app?.logger.notice("Engine Timer Started.")
    }
}
