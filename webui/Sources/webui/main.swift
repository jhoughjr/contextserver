import TokamakDOM

struct TokamakApp: App {
    var body: some Scene {
        WindowGroup("Context Server") {
            ContentView()
        }
    }
}

/*
 // Create WebSocket connection.
 const socket = new WebSocket('ws://localhost:8080');

 // Connection opened
 socket.addEventListener('open', function (event) {
     socket.send('Hello Server!');
 });

 // Listen for messages
 socket.addEventListener('message', function (event) {
     console.log('Message from server ', event.data);
 });
 */
import JavaScriptKit
import Foundation
import TokamakShim
import OpenCombine

public struct ContextObservation:Codable, Hashable {
    let timestamp:Date
    let app:String
    let ctx:String
    let origin:String
    
}

struct ContentView: View {

    var socket = WebSocket(url: URL(string: "ws://localhost:8080/context")!)
    @State var fuck:AnyCancellable?
    
    @State var messages = [ContextObservation]()
    
    var body: some View {
        HStack {
        VStack(alignment:.leading) {
            Text("Context Server")
                .font(.title)
            Divider()
            Spacer()
            ScrollView {
                ForEach(messages.sorted(by: { a, b in
                    a.timestamp > b.timestamp
                }), id:\.self) { message in
                    HStack(alignment:.bottom) {
                        Text("\(message.timestamp)")
                    VStack(alignment:.leading) {
                        Text(message.app)
                        Text(message.ctx)
                    }
                    }
                }
            }
        }
            Spacer()
        }
        .onAppear {

            fuck = socket.messages().sink(receiveValue: { m in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .millisecondsSince1970
                
                if let o = try? decoder.decode(ContextObservation.self,
                                                from: m.data(using: .utf8)!) {
                $messages.wrappedValue.append(o)
                    print("decoded \(o.timestamp.timeIntervalSince1970)")
                }
            })

        }
    }
}

// @main attribute is not supported in SwiftPM apps.
// See https://bugs.swift.org/browse/SR-12683 for more details.
TokamakApp.main()
