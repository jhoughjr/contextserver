//
//  ContextEngine.swift
//  
//
//  Created by Jimmy on 3/10/22.
//

import AppKit
import Vapor

public struct ContextObservation:Content {
    let app:String
    let ctx:String
    let timestamp:String
    let origin:String
}

public class ContextEngine: NSObject {
    
    public static let shared = ContextEngine(app:nil)
    public var vaporApp:Application?

    private var currentAppId = ""
    private var currentContextId = ""
    public var observationHistory = [ContextObservation]()
    
    public func currentObservation() -> ContextObservation {
        ContextObservation(app: currentAppId, ctx: currentContextId, timestamp: Date().rfc1123, origin: "")
    }
    
    public func probeContext() {
        vaporApp?.logger.info("probing...")
        currentContextId = Scripts.resultOfScript(for: currentAppId)
        vaporApp?.logger.info("context is \(currentContextId)")
        
        observationHistory.append(currentObservation())
        // after probe see if changed if so notify
        
        if let last = observationHistory.last {
                let nextToLast = observationHistory[ observationHistory.endIndex - 1]
                
                if last.app == nextToLast.app && nextToLast.ctx == last.ctx {
                    notifyClients()
                  
                }
        }
    }
    
    private func notifyClients() {
        for c in ClientMonitor.shared.contextClients {
            if let coded = try? JSONEncoder().encode(observationHistory.last),
               let codedString = String(data: coded, encoding: .utf8) {
                if !c.socket.isClosed {
                    c.socket.send(codedString)
                }else {
                   purgeClosedConnections()
                }
            }
        }
    }
    
    private func purgeClosedConnections() {
        ClientMonitor.shared.contextClients.forEach { connection in
            if connection.socket.isClosed {
                if let idx = ClientMonitor.shared.contextClients.firstIndex(where: { c in
                    c.socket.isClosed
                }) {
                    ClientMonitor.shared.contextClients.remove(at: idx)
                }
            }
        }
    }
    
    private var obs:NSKeyValueObservation?
    
    public func startObservingMenubarOwner() {
        vaporApp?.logger.info("Starting observation for \\.menuBarOwningApplication ...")
        obs = NSWorkspace.shared.observe(\.menuBarOwningApplication,
                                              options: [.new]) {[weak self] ws, change in
            
            if let bundleID = change.newValue??.bundleIdentifier {
                self?.vaporApp?.logger.info("app changed to \(bundleID)")
                self?.currentAppId = bundleID
                self?.probeContext()
            }
        }
    }
    
    public func stopObservingMenubarOwner() {
        obs = nil
    }
    
    public init(app:Application?) {
        super.init()
        self.vaporApp = app
        startObservingMenubarOwner()
    }
}
