//
//  File.swift
//  
//
//  Created by Jimmy on 3/27/22.
//

import Vapor

class TimerRecorderSettingsResolver {
    static let shared = TimerRecorderSettingsResolver()
    
    public func startTiming() {
        EngineTimer.shared.settings = EngineTimerSettings(isTiming: true)
    }
    
    public func stopTiming() {
        let recorder = EngineTimeRecorder.shared
        EngineTimer.shared.settings = EngineTimerSettings(isTiming: false)
        
        // cant record if not timing
        recorder.settings = EngineTimeRecorderSettings(updatePoint: recorder.settings.updatePoint,
                                                       mongoConnectionString: recorder.settings.mongoConnectionString,
                                                       isRecording: false)
    }
    
    // must time to record tome
    public func startRecording() {
        let recorder = EngineTimeRecorder.shared
        EngineTimer.shared.settings = EngineTimerSettings(isTiming: true)
        
        recorder.settings = EngineTimeRecorderSettings(updatePoint: recorder.settings.updatePoint,
                                                       mongoConnectionString: recorder.settings.mongoConnectionString,
                                                       isRecording: true)
    }
    
    // can time and not record
    public func stopRecording() {
        let recorder = EngineTimeRecorder.shared
        recorder.settings = EngineTimeRecorderSettings(updatePoint: recorder.settings.updatePoint,
                                                       mongoConnectionString: recorder.settings.mongoConnectionString,
                                                       isRecording: false)
    }
}
