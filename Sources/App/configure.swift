import Vapor
import Leaf
import MongoKitten

extension Request {
    public var mongoDB: MongoDatabase {
        return application.mongoDB.hopped(to: eventLoop)
    }
}

private struct MongoDBStorageKey: StorageKey {
    typealias Value = MongoDatabase
}

extension Application {
    public var mongoDB: MongoDatabase {
        get {
            storage[MongoDBStorageKey.self]!
        }
        set {
            storage[MongoDBStorageKey.self] = newValue
        }
    }
    
    
    public func initializeMongoDB(connectionString: String) throws {
        self.mongoDB = try MongoDatabase.lazyConnect(connectionString, on: self.eventLoopGroup)
    }
}

public func configure(_ app: Application) throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.leaf.configuration.rootDirectory = app.directory.viewsDirectory
    app.views.use(.leaf)
    app.lifecycle.use(EngineLifeCycle())
    
    try app.initializeMongoDB(connectionString: "mongodb://127.0.0.1:27017/contextengine")
    try routes(app)
    
   
}
