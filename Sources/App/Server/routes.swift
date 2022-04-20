import Vapor
import Foundation
import Network
import NIOTransportServices
import Leaf

func encode<T: Codable>(_ o: T) -> String  {
    
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .millisecondsSince1970
    encoder.outputFormatting = [.prettyPrinted,.withoutEscapingSlashes,.sortedKeys]
    if let encoded = try? encoder.encode(o),
       let jsonString = String(data: encoded, encoding: .utf8) {
        return jsonString
    }else {
        return "\(o)"
    }
}

struct PrettyDateTag: LeafTag {

    func render(_ ctx: LeafContext) throws -> LeafData {
        struct NowTagError: Error {}

        switch ctx.parameters.count {
        case 1:
            guard let date = ctx.parameters[0].string else {
                throw NowTagError()
            }
        default:
            throw NowTagError()
        }
        let date = Date(timeIntervalSince1970: ctx.parameters.first?.double ?? 0.0)
        let dateAsString = date.formatted(date: .numeric, time: .complete)
        return LeafData.string(dateAsString)
    }
}


func routes(_ app: Application) throws {
    
    // basic web admin interface
    
    app.get("leaf", "websocketprompt") { req async throws -> View in
        return try await req.view.render("websocketprompt", ["title":"Websocket Command Prompt",
                                                             "date":Date().formatted(date: .complete,
                                                                            time: .complete),
                                                             "baseURL":"http://\(app.http.server.configuration.hostname):\(app.http.server.configuration.port)"])
    }
    
    app.get("leaf","engine") { req async throws -> View in
        
        struct LatestLeaf: Content {
            let title:String
            let statusJson:String
            let status:ProbeAttempt?
            let date:String
            let baseURL:String
        }
        
        let ctx = ContextEngine.shared.probeHistory.last

        let foo = LatestLeaf(title: "Latest Probe",
                             statusJson: encode(ctx),
                             status: ctx,
                             date: Date().formatted(date: .complete,
                                                    time: .complete),
                             baseURL: "http://\(app.http.server.configuration.hostname):\(app.http.server.configuration.port)")
        
        return try await req.view.render("engine",foo)
    }
    
    app.get("leaf","history") { req async throws -> View in
        let ctx = ContextEngine.shared.probeHistory.sorted { a, b in
            a.timestamp > b.timestamp
        }
        
        struct Foo:Encodable {
            let title:String
            let jsonHistory:String
            let history:[ProbeAttempt]
            let date:String
            let baseURL:String
        }
        
        let jh = App.encode(ctx)
        app.logger.info("encoded \(jh)")
        return try await req.view.render("history", Foo(title: "Probe History",
                                                        jsonHistory: jh ,
                                                        history: ctx,
                                                        date: Date().formatted(date: .complete,
                                                                               time: .complete),
                                                        baseURL: "http://\(app.http.server.configuration.hostname):\(app.http.server.configuration.port)"))

    }
    
    app.get("leaf","state") { req async throws -> View in
        let ctx = ContextEngine.shared.engineState
        return try await req.view.render("state",  ["title":"Engine State",
                                                       "state" : encode(ctx),
                                                       "date":Date().formatted(date: .complete,
                                                                               time: .complete),
                                                    "baseURL":"http://\(app.http.server.configuration.hostname):\(app.http.server.configuration.port)"])
    }
    
    app.get("leaf","welcome") { req async throws -> View in
        return try await req.view.render("welcome",  ["title" : "Welcome to Context Engine",
                                                      "build" : Commands.ver.rawValue,
                                                       "date" : Date().formatted(date: .complete,
                                                                                time: .complete),
                                                      "baseURL":"http://\(app.http.server.configuration.hostname):\(app.http.server.configuration.port)"])
    }
    
    app.get("leaf","times") { req async throws -> View in
        
        let times = EngineTimer.shared.appTimes.map { AppTime(app: $0.key, seconds: $0.value) }
        
        struct AppTime:Content {
            let app:String
            let seconds:Double
        }
        
        struct AppTimesLeaf:Encodable {
            let title:String
            let appTimes:[AppTime]
            let appTimesJson:String
            let date:String
            let baseURL:String
            let build:String
        }
        
        let ctx = AppTimesLeaf(title: "Context Engine App Times",
                               appTimes:  times.sorted(by: { a, b in
            a.seconds > b.seconds
        }) ,
                               appTimesJson: App.encode(times),
                               date: Date().formatted(date: .complete,
                                                      time: .complete),
                               baseURL: "http://\(app.http.server.configuration.hostname):\(app.http.server.configuration.port)",
                               build:Commands.ver.rawValue)
        
        return try await req.view.render("times",  ctx)
    }
    
    app.get("leaf","settings") { req async throws -> View in
        let ctx = ContextEngine.shared.engineSettings
        
        return try await req.view.render("settings",  ["title":"Engine Settings",
                                                       "settings" : encode(ctx),
                                                       "date":Date().formatted(date: .complete,
                                                                               time: .complete),
                                                       "baseURL":"http://\(app.http.server.configuration.hostname):\(app.http.server.configuration.port)"])
    }
  
    app.get("leaf","settings","engineTimeRecorder") { req async throws -> View in
        struct TimerRecSettings:Content {
            let recorder:EngineTimeRecorderSettings
            let timer:EngineTimerSettings
        }
        let ctx = EngineTimeRecorder.shared.settings
        let ctx2 = EngineTimer.shared.settings
        let set = TimerRecSettings(recorder: ctx,
                                timer: ctx2)
        
        
        return try await req.view.render("engineTimeRecorder",  ["title":"Engine Timer Settings",
                                                                "settings" : encode(set),
                                                                "date":Date().formatted(date: .complete,
                                                                                        time: .complete),
                                                                "baseURL":"http://\(app.http.server.configuration.hostname):\(app.http.server.configuration.port)"])
}
    
    // JSON Interface

    // timer
    app.get("json","times") { req -> String in
        encode(EngineTimer.shared.appTimes)
    }
    
    app.get("json","settings","engineTimer") { req -> String in
        encode(EngineTimer.shared.settings)
    }
    
    app.post("json","settings","engineTimer","isTiming") { req -> String in
        
        let onOffReq = try req.content.decode(EngineTimerOnOffRequest.self)
        let new = EngineTimerSettings(isTiming: onOffReq.isTiming)
        
        EngineTimer.shared.settings = new
        return encode(new)
    }
    
    // recorder
    app.get("json","settings","engineTimeRecorder") { req -> String in
        encode(EngineTimeRecorder.shared.settings)
    }
    
    app.post("json","settings","engineTimeRecorder","isRecording") { req -> String in
        
        let onOffReq = try req.content.decode(EngineTimeRecorderOnOffRequest.self)
        let new = EngineTimeRecorderSettings(
                                             mongoConnectionString: EngineTimeRecorder.shared.settings.mongoConnectionString,
                                             isRecording: onOffReq.isRecording)
        
        if onOffReq.isRecording {
            if !EngineTimer.shared.settings.isTiming {
                EngineTimer.shared.settings.isTiming = true
            }
        }
        EngineTimeRecorder.shared.settings = new
        return encode(new)
    }
    
    app.post("json","settings","engineTimeRecorder","mongoConnectionString") { req -> String in
        
        let conStringReq = try req.content.decode(MongoConnectionStringRequest.self)
        let new = EngineTimeRecorderSettings(
                                             mongoConnectionString: conStringReq.string)
        
        EngineTimeRecorder.shared.settings = new
        return encode(new)
    }
    
    
    // engine
    app.post("json","settings","engine","validateScriptPath") { req -> String in
        
        let validation = try req.content.decode(ScriptPathValidation.self)
        let res = try await ContextEngine.shared.isValidScriptPath(validation)
        if res.isValid == true {
            // should access storage to set new value
            UserDefaults.standard.set(validation.path, forKey: "scriptSourceLocation")
            UserDefaults.standard.synchronize()
            app.logger.info("set new script source path \(validation.path)")
        }
        let coded = encode(res)
        req.logger.debug("\(coded)")
        return coded
    }
    
    app.get("json","settings","engine","ignoredApps") { req -> String in
        encode(ContextEngine.shared.ignoredBundleIDs)
    }
    
    app.post("json","settings","engine","ignoredApps") { req -> String in
        app.logger.info("\(req.body)")
        
        let ignoreOp = try req.content.decode(IgnoredAppRequest.self)
        switch ignoreOp.op {
        case .add:
            ContextEngine.shared.ignoredBundleIDs.append(ignoreOp.bundleID)
            app.logger.info("\(ContextEngine.shared.ignoredBundleIDs)")
        case .remove:
            if let i = ContextEngine.shared.ignoredBundleIDs.firstIndex(of: ignoreOp.bundleID) {
                ContextEngine.shared.ignoredBundleIDs.remove(at: i)
            }
        }
        return encode(ContextEngine.shared.ignoredBundleIDs)
    }
    
    app.get("json","engine","state") { req -> String in
        encode(ContextEngine.shared.state())
    }
    
    // to turn on.off
    app.post("json","engine","state") { req -> String in
        
        let onOff = try req.content.decode(EngineOnOffRequest.self)
        if onOff.value == 1 {
            ContextEngine.shared.start()
        }else {
            ContextEngine.shared.stop()
        }
        return encode(ContextEngine.shared.state())
    }
    
    //
    app.post("json","engine","state","probe") { req -> String in
        
        ContextEngine.shared.probeContext()
        return App.encode([""])
    }
    
    // to see what needs support added
    app.get("json","engine","unhandledApps") { req -> String in
        encode(Scripts.unhandledAppIDs)
    }

    // get settings for how the engine works
    app.get("json","settings","engine") { req -> String in
        encode(ContextEngine.shared.engineSettings)
    }

    
    // get info from engine
    app.get("json","currentObservation") { req -> String in
        encode(ContextEngine.shared.currentObservation())
    }

    app.get("json","probeHistory") { req -> String in
        encode(ContextEngine.shared.probeHistory)
    }

    app.get("json","observationHistory") { req -> String in
        encode(ContextEngine.shared.observationHistory)
    }
    
    // server info
    app.get("json","routes") { req -> String in
        encode(["routes":["json":["get":["engine",
                                         "version",
                                         "unhandledApps",
                                         "settings",
                                         "currentObservation",
                                         "probeHistory",
                                         "observationHistory",
                                         "times"],
                                  "post":["setttings/validateScriptPath",
                                          "settings/ignoredApps"]
                                 ],
                          "leaf":["get":["welcome",
                                         "settings",
                                         "state",
                                         "engine",
                                         "history",
                                         "websocketprompt"],
                          "ws":["context","command"]
                                 ]
                         ]
               ])
    }

    // server info
    app.get("json","version") { req -> String in
        encode(Commands.ver.execute(""))
    }
    
    app.post("json", "scripts") { req -> String in
        struct ScriptRequest:Content {
            let appID:String
        }
        if let request = try? req.content.decode(ScriptRequest.self) {
            var foo = [String:String]()
            foo["script"] = Scripts.script(for: request.appID)?.source
            foo["appID"] = request.appID
            return App.encode(foo)
        }else {
            return ""
        }
    }
    
    app.post("json", "strategies") { req -> String in
        struct StrategyRequest:Content {
            let appID:String
        }
        
        if let request = try? req.content.decode(StrategyRequest.self) {
            var foo = [String:String]()
            foo["strategy"] = App.encode(ContextEngine.shared.strategy(for: request.appID))
            foo["appID"] = request.appID
            return App.encode(foo)
        }else {
            return ""
        }
        
    }
    
    // Websocket Interface
    app.webSocket("ws","context") { req, ws in
        app.logger.info("\(String(describing: req.remoteAddress)) connected to context channel")
        
        if !ClientMonitor.shared.contextClients.contains(where: { connection in
            return connection.request.remoteAddress == req.remoteAddress
        }) {
            let connection = ClientMonitor.ClientConnection(request: req, socket: ws)
            ClientMonitor.shared.contextClients.append(connection)
        }
        ws.send(encode(ContextEngine.shared.currentObservation()) )
    }
    
    app.webSocket("ws","command") { req, ws in

        app.logger.info("\(String(describing: req.remoteAddress)) connected to command channel")

        if !ClientMonitor.shared.commandClients.contains(where: { connection in
            return connection.request.remoteAddress == req.remoteAddress
        }) {
            
            let connection = ClientMonitor.ClientConnection(request: req, socket: ws)
            ClientMonitor.shared.commandClients.append(connection)
            
            ws.onText { ws, string in
                CommandProcessor.shared.handleCommand(commandString: string, for: ws)
            }
            ws.send("READY>")
        }
        
    }
    
    app.logger.info("Routes online: \(app.routes.all.count)")
    for r in app.routes.all {
        app.logger.info("\(r)")
    }
}
