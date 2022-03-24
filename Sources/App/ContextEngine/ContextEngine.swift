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
    let scriptSourceLocation:String
}
public struct EngineState2:Codable {
    var launchedAt:Date?
    var timestamp:Date
    var observations:UInt
    var running:Bool
}

public struct ServerState:Codable {
    let socketClients:UInt
}

public struct ScriptPathValidation:Content {
    let path:String
}

public struct ScriptPathValidationResult:Content {
    let isValid:Bool
}

public class ContextEngine: NSObject {
    
    public static let shared = ContextEngine(app:nil)
    
    public var vaporApp:Application?

    private var currentAppId = ""
    private var currentContextId = ""
    
    private let encoder = JSONEncoder()
    
    public var observationHistory = [ContextObservation]()
    public var probeHistory = [ProbeAttempt]()
    public var engineSettings = EngineSettings(scriptSourceLocation: Scripts.sourceLocation.absoluteString)
    public var ignoredBundleIDs = [String]()
    
    public var engineState:EngineState2? = nil
    
    public func isValidScriptPath(_ p:ScriptPathValidation) async throws -> ScriptPathValidationResult {
        ScriptPathValidationResult(isValid:directoryExistsAtPath(p.path))

    }
    
    fileprivate func directoryExistsAtPath(_ path: String) -> Bool {
        
        guard !path.isEmpty else { return false }
        
        if FileManager.default.isReadableFile(atPath: path) {
            vaporApp!.logger.info("readable")
        }else {
            vaporApp!.logger.info("not readable")
        }
        do {
            let u = URL(string:path)
            _ = try Data(contentsOf: u!, options: [])
        }
        catch {
            if error.localizedDescription.contains("no such file") {
                return false
            }else if error.localizedDescription.contains("file") {
                return true
            }
            return false
        }
        return false
    }
    
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
    
    //TODO: Add logic to ignore query string in browser apps
    
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
        probeHistory.append(ProbeAttempt(timestamp:Date(),
                                         strategy: s,
                                         script:Scripts.script(for: observation.app)?.source ?? "",
                                         observation: observation))
        
        engineState = EngineState2(launchedAt: engineState?.launchedAt, timestamp: Date(),
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
        engineState = EngineState2(launchedAt: Date(), timestamp: Date(),
                                   observations: UInt(observationHistory.count),
                                   running: true)
    }
    
    public func stop() {
        obs = nil
        engineState = EngineState2(launchedAt: engineState?.launchedAt, timestamp: Date(),
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
