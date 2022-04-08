//
//  File.swift
//  
//
//  Created by Jimmy on 3/27/22.
//

import Vapor
import MongoKitten

struct TimeCollection:Content {
    var id:ObjectId
    var times:[String:Double]
}

class EngineTimeRecorder {
    
    internal var vaporApp:Vapor.Application?

    static let shared = EngineTimeRecorder()
    
    var settings = EngineTimeRecorderSettings()
    private var recordedTimes = [String:Double]()
    
    public func switched(app:String,time:Double) {
        if self.settings.isRecording {
            Task {
                try await self.recordTime(app: app, seconds: time)
            }
        }
    }
    
    public func ticked(app:String, time:Double) {
//        vaporApp?.logger.info("[RECORDER] tick")
        if self.settings.isRecording {
            Task {
                try await self.recordTime(app: app, seconds: time)
            }
        }
    }
    
    func save() {
        UserDefaults.standard.set(EngineTimer.shared.appTimes,
                                  forKey: "appTimes")
        UserDefaults.standard.synchronize()
    }
    
    public func recordTime(app:String, seconds:Double) async throws {
        save()
    }
}

struct MongoConnectionStringRequest:Content {
    let string:String
}

struct EngineTimeRecorderOnOffRequest:Content {
    let isRecording:Bool
}

struct EngineTimeRecorderSettings:Content {
    
  
    // should pull from storage or env or something central
    public var mongoConnectionString:String = "mongodb://127.0.0.1:27017/contextengine"
    public var isRecording = true
}
