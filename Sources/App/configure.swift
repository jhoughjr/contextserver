import Vapor
import Leaf

public func configure(_ app: Application) throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
  
    app.leaf.configuration.rootDirectory = app.directory.viewsDirectory
    
    app.views.use(.leaf)
    
    app.lifecycle.use(EngineLifeCycle())
    try routes(app)
}
