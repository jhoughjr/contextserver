import Vapor

public func configure(_ app: Application) throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.lifecycle.use(EngineLifeCycle())
    try routes(app)
}
