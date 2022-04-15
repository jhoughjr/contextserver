//
//  ContextEngine.swift
//  
//
//  Created by Jimmy on 3/10/22.
//

import AppKit
import Vapor
import MongoKitten

struct EngineOnOffRequest:Content {
    let value:Int
}

// used in IgnoredAppRequest
enum IgnoredAppOperation:Content {
    case add
    case remove
}

struct IgnoredAppRequest:Content {
    let op:IgnoredAppOperation
    let bundleID:String
}

public enum ContextDiscoveryStrategy:String, Content {
    case script
    case api
}

public enum ProbeInitiator:Content {
    case appSwitch
    case jsonAPI
}

// used in probeHistory
public struct ProbeAttempt:Content {
    let timestamp:Date
    let strategy:ContextDiscoveryStrategy
    let script:String
    let observation:ContextObservation
}

// what we're here fore
public struct ContextObservation:Content {
    let timestamp:Date
    let app:String
    let ctx:String
    let origin:String
}

// things the engine needs
public struct EngineSettings:Codable {
    let scriptSourceLocation:String
}

//
public struct EngineState:Content {
    let engineSettings:EngineSettings
    let currentObservation:ContextObservation
    let history:[ContextObservation]
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
    
    public var icons = [String:Data]()
    
    init(app:Vapor.Application) {
        ContextEngine.shared.vaporApp = app
    }
    
    public var vaporApp:Application?

    private var currentAppId = ""
    
    private var currentContextId = ""
    
    public var observationHistory = [ContextObservation]()
    public var probeHistory = [ProbeAttempt]()
    
    // these should be file based
    public var engineSettings = EngineSettings(scriptSourceLocation: Scripts.sourceLocation.absoluteString) {
        didSet {
            vaporApp?.logger.info("[ENGINE] settings update \(engineSettings)")
        }
    }
    
    // should be persisted?
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
        
        let o = ContextObservation(timestamp: Date(),
                                   app: currentAppId,
                                   ctx: currentContextId,
                                   origin: "\(vaporApp?.http.server.configuration.address)" )
        vaporApp?.logger.info("[ENGINE] observed: \(o)")
        return o
    }
        
    public func probeContext() {
        
        vaporApp?.logger.info("[ENGINE] probing...")

        let s = strategy(for: currentAppId)
        
        switch s {
        case .script:
            currentContextId = Scripts.resultOfScript(for: currentAppId)
        case .api:
            vaporApp?.logger.warning("[ENGINE] \(s) not implemented for any apps yet.")
            currentContextId = APIs.call(APIs.api(for: currentAppId))
        }
        
        let observation = currentObservation()
        
        observationHistory.append(observation)
        
        probeHistory.append(ProbeAttempt(timestamp:Date(),
                                         strategy: s,
                                         script:Scripts.script(for: observation.app)?.source ?? "",
                                         observation: observation))
        
        engineState = EngineState2(launchedAt: engineState?.launchedAt,
                                   timestamp: Date(),
                                   observations: UInt(observationHistory.count),
                                   running: engineState?.running ?? false)
        
        if let last = observationHistory.last {
            
            let nextToLast = observationHistory[ observationHistory.endIndex - 1]
            
            if last.app == nextToLast.app && nextToLast.ctx == last.ctx {
                notifyClients()
            }else {
                vaporApp?.logger.info("[ENGINE]  no change")
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
        
        obs = NSWorkspace.shared.observe(\.menuBarOwningApplication,
                                              options: [.new]) {[weak self] ws, change in
            
            if let bundleID = change.newValue??.bundleIdentifier {
                
                self?.vaporApp?.logger.info("[ENGINE] app changed to \(bundleID)")
                self?.currentAppId = bundleID
                EngineTimer.shared.timedApp = bundleID
                self?.probeContext()
            }
        }
        
        vaporApp?.logger.info("[ENGINE] Started observation for \\.menuBarOwningApplication ...")

        if let bundleID = NSWorkspace.shared.menuBarOwningApplication?.bundleIdentifier {
            currentAppId = bundleID
            EngineTimer.shared.timedApp = bundleID

            probeContext()
        }
        vaporApp?.logger.info("[ENGINE] Initial probe complete.")

    }

    public func stopObservingMenubarOwner() {
        currentAppId = ""
        currentContextId = ""
        obs = nil
        vaporApp?.logger.info("[ENGINE] stopped observing.")
    }
    
    public func start() {
        
        startObservingMenubarOwner()
        engineState = EngineState2(launchedAt: Date(),
                                   timestamp: Date(),
                                   observations: UInt(observationHistory.count),
                                   running: true)
        EngineTimer.shared.timedApp =  NSWorkspace.shared.menuBarOwningApplication?.bundleIdentifier ?? ""

        vaporApp?.logger.info("[ENGINE] started.")

    }
    
    public func stop() {
        EngineTimer.shared.timedApp = ""
        stopObservingMenubarOwner()
        engineState = EngineState2(launchedAt: engineState?.launchedAt,
                                   timestamp: Date(),
                                   observations: UInt(observationHistory.count),
                                   running: false)
    }
    
    public init(app:Application?) {
        super.init()
        self.vaporApp = app
    }
    
    func strategy(for appID:String) -> ContextDiscoveryStrategy {
        // should get from file
        // maybe json
        /*
         [{"bundleID":{"strat":""}}]
         
         */
        return .script
    }
}
