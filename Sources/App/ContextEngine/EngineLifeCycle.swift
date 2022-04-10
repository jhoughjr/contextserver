//
//  EngineLifeCycle.swift
//  
//
//  Created by Jimmy on 3/10/22.
//

import Vapor

struct EngineLifeCycle: LifecycleHandler {

    func didBoot(_ app: Application) throws {
        Scripts.vaporApp = app
        EngineTimeRecorder.shared.vaporApp = app
        EngineTimer.shared.vaporApp = app

        _ = ContextEngine.init(app: app)
        
        app.logger.info("Context Engine Booted.")
        
        ContextEngine.shared.start()
    }
    
    func shutdown(_ application: Application) {
        ContextEngine.shared.stop()
    }

}
