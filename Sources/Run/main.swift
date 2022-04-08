import AppKit
import App
import Vapor


var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
try configure(app)

DispatchQueue.global().async {
    app.logger.info("Running Vapor Application...")
    try? app.run()
}
app.logger.info("Starting main runloop for NSWorkspace observations...")
RunLoop.main.run()
