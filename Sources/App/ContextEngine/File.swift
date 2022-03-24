//
//  File.swift
//  
//
//  Created by Jimmy on 3/23/22.
//

import Foundation

class EngineTimer {
    static let shared = EngineTimer()
    
    var appTimes = [String:TimeInterval]()
    var timedApp = ""
    var total:TimeInterval = 0

    var timer:Timer?
    
    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1,
                                         repeats: true) { t in
            print("Timer fired!")
            if let t = self.appTimes[self.timedApp] {
                self.appTimes[self.timedApp] = t + 1
            }else {
                self.appTimes[self.timedApp] = 1
            }
            
        }
    }
}
