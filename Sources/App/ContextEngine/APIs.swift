//
//  File.swift
//  
//
//  Created by Jimmy on 4/10/22.
//

import Foundation
import WebSocketKit

enum APIType: Codable, CaseIterable {
    case rest
    case WebSocket
}

struct APISpec:Codable {
    let appID:String
    let scheme:String
    let host:String
    let port:Int
    let method:String
    let type:APIType
}

class APIs {
    
    static func api(for appID:String) -> APISpec {
        APISpec(appID: appID, scheme:"",host: "localhost", port: 9000, method: "GET", type: .rest)
    }
    
    static func call(_ api:APISpec) -> String {
        switch api.type {
        case .rest:
            print("call rest endpoint")
        case .WebSocket:
            print("send socket payload")
        }
        return "API result"
    }
}
