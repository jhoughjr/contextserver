//
//  File.swift
//  
//
//  Created by Jimmy on 3/27/22.
//

import Vapor

struct TimeUpdatePointRequest:Content {
    let updatePoint:EngineTimeRecorderSettings.UpdatePoint
}
