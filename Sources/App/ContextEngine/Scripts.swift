
//
//  Scripts.swift
//  ContextEngine
//
//  Created by Jimmy Hough Jr on 1/1/18.
//  Copyright © 2018 2022 Jimmy Hough Jr. All rights reserved.
//

import Cocoa
import Vapor

import OSAKit

class Scripts {

    // should be user configurable
    public static var sourceLocation = URL(fileURLWithPath: "public/context-discovery/scripts/"	)
    
    public static var vaporApp:Vapor.Application? = nil
    
    public static var unhandledAppIDs = [String]()
 
    public static func script(for appID:String) -> OSAScript? {
        
        let url = sourceLocation.appendingPathComponent(
            URL(fileURLWithPath: "\(appID).dataset/\(appID).applescript").relativePath
        )
        
        if let data = try? Data(contentsOf: url) {
            if let source = String(data: data, encoding: .utf8) {
                return OSAScript(source: source)
            }else {
                unhandledAppIDs.append(appID)
                return nil
            }
        }else {
            unhandledAppIDs.append(appID)
            return nil
        }
    }
    
    public static func resultOfScript(for id: String) -> String {
    
        if let s = script(for: id) {
            return runCommand(cmd: "/usr/bin/osascript",
                                args: ["-e", s.source])
        }
        
        return ""
    }
    
    private static func runCommand(cmd: String,
                                   args: [String]) -> String {
        let outPipe = Pipe()
        let proc = Process()
        proc.launchPath = cmd
        let foo = args.map{$0.replacingOccurrences(of: "\r", with: "\n")}
        proc.arguments = foo
        proc.standardOutput = outPipe
        proc.launch()
        proc.waitUntilExit()
        
        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        let res =  String(data: data, encoding: .utf8) ?? "ERROR"
        return res
    }

}

