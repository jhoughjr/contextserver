//
//  ContextEngine.swift
//  
//
//  Created by Jimmy on 3/10/22.
//

import AppKit
import Vapor

public enum ContextDiscoveryStrategy:String,Content {
    case script
    case api
}

public struct ProbeAttempt:Content {
    let timestamp:Date
    let strategy:ContextDiscoveryStrategy
    let observation:ContextObservation
}

public struct ContextObservation:Content {
    let app:String
    let ctx:String
    let timestamp:Date
    let origin:String
}

public struct EngineState:Content {
    let ignoreQueryInBrowserApps:Bool
    let currentObservation:ContextObservation
    let history:[ContextObservation]
}

public class ContextEngine: NSObject {
    
    public static let shared = ContextEngine(app:nil)
    
    public var vaporApp:Application?

    private var currentAppId = ""
    private var currentContextId = ""
    
    private let encoder = JSONEncoder()
    
    public var observationHistory = [ContextObservation]()
    public var probeHistory = [ProbeAttempt]()
    
    public func state() -> EngineState {
        EngineState(ignoreQueryInBrowserApps: false,
                    currentObservation: currentObservation(),
                    history: observationHistory)
    }
    
    public func currentObservation() -> ContextObservation {
        let o = ContextObservation(app: currentAppId,
                                   ctx: currentContextId,
                                   timestamp: Date(),
                                   origin: "")
        vaporApp?.logger.debug("[ENGINE] observed: \(o)")
        return o
    }
    
    public func probeContext() {
        vaporApp?.logger.info("probing...")

        let s = strategy(for: currentAppId)
        
        switch s {
        case .script:
            currentContextId = Scripts.resultOfScript(for: currentAppId)
        case .api:
            vaporApp?.logger.warning("\(s) not implemented for any apps yet.")
            currentContextId = Scripts.resultOfScript(for: currentAppId)
        }
        
        let observation = currentObservation()
        
        observationHistory.append(observation)
        // after probe see if changed if so notify
        probeHistory.append(ProbeAttempt(timestamp:Date(), strategy: s, observation: observation))
        
        if let last = observationHistory.last {
            
            let nextToLast = observationHistory[ observationHistory.endIndex - 1]
            
            if last.app == nextToLast.app && nextToLast.ctx == last.ctx {
                notifyClients()
            }else {
                vaporApp?.logger.info("no change")
            }
        }
    }
    
    private func notifyClients() {
        for c in ClientMonitor.shared.contextClients {
            if let coded = try? encoder.encode(observationHistory.last),
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
    
    func strategy(for appID:String) -> ContextDiscoveryStrategy {
        return .script
    }
}
