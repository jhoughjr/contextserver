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

struct EngineTimerSettings:Content {
    var isTiming:Bool
}

struct EngineTimerOnOffRequest:Content {
    let isTiming:Bool
}


class EngineTimer {
    
    public static let shared = EngineTimer(nil)

    public var settings = EngineTimerSettings(isTiming: true) {
        didSet {
            vaporApp?.logger.info("[TIMER] settings updated \(settings)")
        }
    }
        
    public var vaporApp:Vapor.Application?
    
    public var appTimes = [String:Double]() 
    
    public var timedApp = "" {
        didSet {
            if settings.isTiming {
                EngineTimeRecorder.shared.switched(app: timedApp,
                                                   time: appTimes[timedApp] ?? 0.0)
                timeApp()
            }else {
                vaporApp?.logger.info("[TIMER] not timing.")
            }
        }
    }
    
    private var timer:Timer?
    
    // need to fix recorder needing to clear timing state
    private func tick() {
        
        if self.settings.isTiming {
            if let t = self.appTimes[self.timedApp] {
                self.appTimes[self.timedApp] = t + 1
            }else {
                self.appTimes[self.timedApp] = 1
            }
            
            EngineTimeRecorder.shared.ticked(app: self.timedApp,
                                             time: self.appTimes[self.timedApp] ?? 0.0)
           
        }
    }
    
    private func timeApp() {
        
        if settings.isTiming {
            
//            vaporApp?.logger.notice("[TIMER] Engine Timer scheduling.")

            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1,
                                         repeats: true) { t in
                self.tick()
            }
            
        }
        else {
            vaporApp?.logger.info("[TIMER] timing off.")
            timer?.invalidate()
            timer = nil
        }
    }
  
    func load() {
    
        if let times = UserDefaults.standard.value(forKey: "appTimes") as? [String:Double] {
//            self.appTimes = times
        }
        
    }
    
    public func reset() {
        appTimes.removeAll()
        
        vaporApp?.logger.notice("[TIMER] Engine Timer reset.")
        EngineTimeRecorder.shared.save()
        
    }
    
    init(_ app:Vapor.Application?) {
        vaporApp = app
        app?.logger.notice("[TIMER] Engine Timer Started.")
    }
}
