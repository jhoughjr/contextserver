//
//  EngineLifeCycle.swift
//  
//
//  Created by Jimmy on 3/10/22.
//

import Vapor

struct EngineLifeCycle: LifecycleHandler {

    func willBoot(_ app: Application) throws {
        EngineTimeRecorder.shared.vaporApp = app
        Scripts.vaporApp = app
        ContextEngine.shared.vaporApp = app
        
        ContextEngine.shared.probeContext()
        EngineTimer.shared.vaporApp = app
        app.logger.info("Context Engine ready.")
        
    }
    func shutdown(_ application: Application) {
        ContextEngine.shared.stop()
    }

}
