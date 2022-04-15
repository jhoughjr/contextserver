import AppKit
import App
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
try configure(app)
app.logger.info("*** NOTE ***")
app.logger.info("Ctrl-C does not work to properly shutdown the server. Use the 'shutdown' command @ /ws/command ")
app.logger.info("*** NOTE ***")

DispatchQueue.main.async {

    app.logger.info("Running Vapor Application...")
    try? app.start()
}
app.logger.info("Starting main runloop for NSWorkspace observations...")
RunLoop.main.run()


