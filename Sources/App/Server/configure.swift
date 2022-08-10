import Vapor
import Leaf
import MongoKitten
import NIOSSL

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
    
    app.http.server.configuration.serverName = "vapor4-context-server"

    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    // cors middleware should come before default error middleware using `at: .beginning`
    app.middleware.use(cors, at: .beginning)
    app.logger.info("CORS Middleware installed.")

    do {
    // Enable TLS.
        try app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
            certificateChain: NIOSSLCertificate.fromPEMFile("/path/to/cert.pem").map { .certificate($0) },
            privateKey: .file("/path/to/key.pem")
        )
        app.logger.info("TLS Supported.")

    }
    catch {
        app.logger.error("No cert found. No HTTPS :(")
    }
    
    app.leaf.configuration.rootDirectory = app.directory.viewsDirectory
    app.views.use(.leaf)
    app.logger.info("Template Engine configured.")

    do {
        try app.initializeMongoDB(connectionString: "mongodb://127.0.0.1:27017/contextengine")
        app.logger.info("MongoKitten initialzed.")
    }
    catch {
        app.logger.warning("Can't connect to MongoDB. No persistence :(")
    }
    
    app.leaf.tags["pdate"] = PrettyDateTag()

    try routes(app)
    app.logger.info("Routes installed.")
    app.lifecycle.use(EngineLifeCycle())
    CommandProcessor.shared.app = app
    app.logger.info("Engine Lifecyle installed.")
    app.logger.info("WebsocketCommands Installed.")
 
}
