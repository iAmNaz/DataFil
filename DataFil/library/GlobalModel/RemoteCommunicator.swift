//
//  watchCommunicator.swift
//  DataFil
//
//  Created by Alex Gubbay on 12/03/2017.
//  Copyright © 2017 Alex Gubbay. All rights reserved.
//
/*
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 The software implementation below is NOT designed to be used in any situation where the failure of the algorithms code on which they rely or mathematical assumptions made therin could lead to the harm of the user or others, property or the environment. It is NOT designed to prevent silent failures or fail safe.
 */

import Foundation
import WatchConnectivity

/**
 Creates and manages sessions with a remote Watch or iPhone. Sends messages as key value pairs and notifies subscibers of a particular key of an incoming message under that key. Singleton.
 */
class RemoteCommunicator: NSObject, WCSessionDelegate {

    static let sharedInstance = RemoteCommunicator()
    var watchObservers: [String: [(Any) -> Void]]
    var delegates = [AnyObject]()
    var session = WCSession.default()
    var deviceId = "unknown"

    /**
     Starts a new session with the remote device. Will print error to console if not possible.
     - parameter deviceId: ID for communication printed alongside debug messages to help trace source.
     */
    func start(deviceId: String){
        print("starting")
        self.deviceId = deviceId
        if WCSession.isSupported() {
            if session.hasContentPending{
                print("may have old data")
            }
            session.delegate = self
            session.activate()
            session = WCSession.default()
            print("comms live on \(deviceId)")
        }else{
            print("coms not supported on \(deviceId)")
        }
    }
    override init(){
        watchObservers = [:]
    }
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?){
    }
    /**
     Checks if device supports Apple Watch communication.
     - returns: True if device supports Apple Watch communication.
     */
    func isSupported() -> Bool{
        return WCSession.isSupported()
    }

    #if os(iOS)
    func sessionDidDeactivate(_ session: WCSession) {
        //ERM
    }
    func sessionDidBecomeInactive(_ session: WCSession) {
        //Do some stuff here I gueess
    }
    #endif
    public func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        //
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {

        for k in message.keys{
            notifyObservers(key: k, data: message[k] as Any)
        }
    }
    /**
     Sends message to remote device if possible. Will print to console if not.
     - paramter key: Identifies which subscibrers on the remote device to notify. 
     - parameter value: The message
     */
    func sendMessage(key: String, value: Any){

        if (session.isReachable) {
            let message = [key: value]
            session.sendMessage(message, replyHandler: nil)
        }else{
            print("remote unreachable from \(deviceId)")
        }
    }
    /**
     - returns: True if an Apple Watch is connected.
    */
    func watchIsConnected() -> Bool{
        return !session.isReachable
    }

    /**
     Adds an observer under a key. If a message arrives with that key, the message will be passed into the callback and executed.
     - parameter key: Key of message to listen for.
     - parameter update: Cllback function to pass message into. 
     */
    func addObserver(key: String, update: @escaping (Any) -> Void) {
        DispatchQueue.main.async {
            if var value = self.watchObservers[key]{
                value.append(update)
            }else{
                self.watchObservers[key] = [update]
            }
        }
    }
    private func notifyObservers(key: String, data: Any) {

        if let registeredObservers = watchObservers[key]{

            for i in registeredObservers {
                i(data)
            }
        }
    }
}
