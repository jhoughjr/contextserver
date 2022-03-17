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
    let script:String
    let observation:ContextObservation
}

public struct ContextObservation:Content {
    let timestamp:Date
    let app:String
    let ctx:String
    let origin:String
}

public struct EngineState:Content {
    let engineSettings:EngineSettings
    let currentObservation:ContextObservation
    let history:[ContextObservation]
}

public struct EngineSettings:Codable {
    let ignoreQueryInBrowserApps:Bool
    let scriptSourceLocation:String
}
public struct EngineState2:Codable {
    var launchedAt:Date?
    var observations:UInt
    var running:Bool
}

public struct ServerState:Codable {
    let socketClients:UInt
}

public class ContextEngine: NSObject {
    
    public static let shared = ContextEngine(app:nil)
    
    public var vaporApp:Application?

    private var currentAppId = ""
    private var currentContextId = ""
    
    private let encoder = JSONEncoder()
    
    public var observationHistory = [ContextObservation]()
    public var probeHistory = [ProbeAttempt]()
    public var engineSettings = EngineSettings(ignoreQueryInBrowserApps: false,
                                               scriptSourceLocation: Scripts.sourceLocation.absoluteString)
    
    public var engineState:EngineState2? = nil
    
    public func state() -> EngineState {
        EngineState(engineSettings: engineSettings ,
                    currentObservation: currentObservation(),
                    history: observationHistory.sorted(by: { a, b in
            a.timestamp > b.timestamp
        }))
    }
    
    public func currentObservation() -> ContextObservation {
        
        let o = ContextObservation(timestamp: Date(), app: currentAppId,
                                   ctx: currentContextId,
                                   origin: "\(vaporApp!.http.server.configuration.address)" )
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
        // should store thsi with engine state to map the observation with the probe it came form
        probeHistory.append(ProbeAttempt(timestamp:Date(), strategy: s,script:Scripts.script(for: observation.app)?.source ?? "", observation: observation))
        
        engineState = EngineState2(launchedAt: engineState?.launchedAt,
                                   observations: UInt(observationHistory.count),
                                   running: engineState?.running ?? false)
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
            if !c.socket.isClosed {
                c.socket.send(encode(currentObservation()))
            }else {
               purgeClosedConnections()
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
    
    public func start() {
        startObservingMenubarOwner()
        engineState = EngineState2(launchedAt: Date(),
                                   observations: UInt(observationHistory.count),
                                   running: true)
    }
    
    public func stop() {
        obs = nil
        engineState = EngineState2(launchedAt: engineState?.launchedAt,
                                   observations: UInt(observationHistory.count),
                                   running: false)
    }
    
    public init(app:Application?) {
        super.init()
        self.vaporApp = app
        start()
    }
    
    func strategy(for appID:String) -> ContextDiscoveryStrategy {
        return .script
    }
}
