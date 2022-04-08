//
//  File.swift
//  
//
//  Created by Jimmy on 4/5/22.
//

import Foundation
//
//  File.swift
//
//
//  Created by Jimmy on 3/27/22.
//

import Vapor
import MongoKitten

class IconRecorder {
    
    internal var vaporApp:Vapor.Application?

    static let shared = IconRecorder()
    
    var settings = IconRecorderSettings()
    private var recordedTimes = [String:Double]()
    
   
}

struct IconRecorderOnOffRequest:Content {
    let isRecording:Bool
}

struct IconRecorderSettings:Content {
    public var mongoConnectionString:String = "mongodb://127.0.0.1:27017/contextengine"
    public var isRecording = true
}
