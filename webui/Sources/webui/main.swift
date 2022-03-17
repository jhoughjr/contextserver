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

struct ObservationView: View {
    //
    var observation:ContextObservation
    let dateFormatter = DateFormatter()
    
    func date() -> String {
        
        dateFormatter.timeStyle = .full

        let timeString = dateFormatter.string(from: observation.timestamp)//observation.timestamp.formatted(date: .omitted, time: .complete)
        let dateString = "" //observation.timestamp.formatted(date: .complete, time: .omitted)
        return "\(timeString) \(dateString)"
    }
    
    var body: some View {
        HStack(alignment:.bottom, spacing:8.0) {
            Text(date())
                .padding()
            VStack(alignment:.leading) {
                Text(observation.app.components(separatedBy: ".").last?.capitalized ?? observation.app)
                    .fontWeight(.bold)
                Text(observation.ctx)
                    .fontWeight(.light)
            }
        }
    }
}

struct ObservationsView: View {
    
    private var socket = WebSocket(url: URL(string: "ws://localhost:8080/ws/context")!)
    
    @State private var observationRelay:AnyCancellable?
    @State private var observations = [ContextObservation]()
    
    var body: some View {
        VStack(alignment:.leading) {

            Text("Observations")
                .font(.title)
            Divider()
      
            Text("\(observations.count)")
            List {
                
                ForEach(observations.sorted(by: { a, b in
                    a.timestamp > b.timestamp
                }), id:\.self) { message in
                   ObservationView(observation: message)
                }

            }
            Spacer()
        }
        .onAppear {

            observationRelay = socket.messages().sink(receiveValue: { m in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .millisecondsSince1970
                
                if let o = try? decoder.decode(ContextObservation.self,
                                                from: m.data(using: .utf8)!) {
                    $observations.wrappedValue.append(o)
                }
            })

        }
    }
}

struct ContentView: View {

    var body: some View {
        HStack {
        VStack { //
            ObservationsView()
            Spacer()
        }
            Spacer()
        }
    }
}

// @main attribute is not supported in SwiftPM apps.
// See https://bugs.swift.org/browse/SR-12683 for more details.
TokamakApp.main()
