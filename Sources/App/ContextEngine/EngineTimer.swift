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

class EngineTimeRecorder {
    internal var vaporApp:Vapor.Application?

    static let shared = EngineTimeRecorder()
    public var updatePoint:UpdatePoint = .immediately
    
    public enum UpdatePoint {
        case onSwitch // always updated on switch
        case immediately // updates on switch and every second
    }
    
    public func switched(app:String,time:Double) {
        if self.updatePoint == .onSwitch {
            Task {
                try await self.recordTime(app: app, seconds: time)
            }
        }
    }
    
    public func ticked(app:String, time:Double) {
        if self.updatePoint == .immediately {
            Task {
                try await self.recordTime(app: app, seconds: time)
            }
        }
    }
    
    public func recordTime(app:String, seconds:Double) async throws {
        
        vaporApp?.logger.info("recording time \(seconds) for \(app)")

        if let times = vaporApp?.mongoDB["times"] {

            if let oldtimes = try? await times.findOne(["source":"me"]).get() {
                
                vaporApp?.logger.info("\(oldtimes)")
                var newDoc = Document()
                newDoc["source"] = "me"
                newDoc["id"] = oldtimes["id"]
                var previous = oldtimes[app] as? Double
                
                for f in oldtimes {
                    if f.0 != "source" {
                        newDoc.appendValue(f.1, forKey: f.0)
                    }
                }
                
                if let p = previous {
                newDoc[app] = seconds + p
                }else {
                    newDoc[app] = seconds
                }
                
                
                let reply = try await times.upsert(newDoc, where: ["source":"me"]).get()
                vaporApp?.logger.info("\(reply)")
                EngineTimer.shared.appTimes[app] = 0

            }else {
                vaporApp?.logger.info("no match for times.findOne([\"source\":\"me\"]) ")
                var newDoc = Document()
                newDoc["source"] = "me"
                
                newDoc[app] = seconds
                let reply = try await times.insert(newDoc).get()
                vaporApp?.logger.info("\(reply)")
            }
        }
        else {
            vaporApp?.logger.info("couldnt get times collection. check connection string.")
        }
    }
}

class EngineTimer {
    
    public static let shared = EngineTimer(nil)

    internal var vaporApp:Vapor.Application?
    
    public var appTimes = [String:Double]()
    
    public var timedApp = "" {
        didSet {
            EngineTimeRecorder.shared.switched(app: timedApp, time: appTimes[timedApp] ?? 0.0)
            timeApp()
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
                self.appTimes[self.timedApp] = 1
            }
            EngineTimeRecorder.shared.ticked(app: self.timedApp, time: self.appTimes[self.timedApp] ?? 0.0)
        }
    }

    init(_ app:Vapor.Application?) {
        vaporApp = app
        app?.logger.notice("Engine Timer Started.")
    }
}
