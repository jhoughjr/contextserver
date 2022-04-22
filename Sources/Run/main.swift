import App
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
try configure(app)

let appThread = Thread {
    do {
        try app.run()
        exit(0)
    } catch {
        print(error)
        exit(1)
    }
}

appThread.name = "Application"
appThread.start()

RunLoop.main.run()
