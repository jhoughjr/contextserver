# contextserver
Vapor 4 / Swift 5.5 command line application to monitor and serve the current usage context of the user.

# Conceptual Overview
   Context Server consists of two main parts, the Context Engine and the server.
   The engine discovers the use context, and the server provides a websocket
   interface to monitor and react to changes in the engine state, as well as a REST like API.
   
   Context Engine
   The engine operation consists of two parts, app detection and when possible, context detection.
   App detection is implemented via KVO on NSWorkspace.menuBarOwningApplication.
   Context detection is implemented via using osascript to execute applescript against the currently detected app.
      (Next on the roadmap is to support JS and custom API based context detection as well)
   This script should return a string.
   
   Server
   The server is powered by Vapor 4 thus by default is reachable at http://localhost:8080 .
   
        endpoint                  returns
       /                          Basic status information 
       /engine                    State of the engine overall 
       /currentObservation        ContextObservation struct 
       /probeHistory              Array of ProbeAttempts
       /observationHistory        Array of ContextObservations
       
       websocket endpoint         returns
       /context                   the latest ContextObservation, when it occurs
       /command                   Variable. Depends on speccific command. TBI
       
# Getting Started
