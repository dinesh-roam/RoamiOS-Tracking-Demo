//
//  RoamHelper.swift
//  RoamDemo
//
//  Created by Roam on 09/11/23.
//

import Foundation
import Roam
import UIKit

final class RoamHelper {
    
    static let shared = RoamHelper()
    
    var locations: [RoamLocation] = [] {
        didSet {
            updateMapView()
        }
    }
    
    private func updateMapView() {
        NotificationCenter.default.post(name: Notification.Name("DidUpdateLocations"), object: nil)
    }
    
    //MARK: - ROAM Methods

    func initalize() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        Roam.delegate = self
        
        Roam.initialize("")
        
        Roam.requestLocation()
    }
    
    //MARK: -
    func setupRoam(completion: @escaping (Error?) -> Void) {
        if let roamUserId = UserDefaults.standard.string(forKey: "ROAM_USERID") {
            //        if let roamUserId = storage.roamUser {
            Roam.getUser(roamUserId) { [weak self] roamUser, error in
                print("Roam user loaded: \(roamUser?.userId ?? "na") or error: \(error?.message ?? "na")")
                if error != nil {
                    self?.createUser(completion)
                } else {
//                    if let events = roamUser?.locationEvents,
//                       !events {
                    print("Roam Toggling events")
                    Roam.toggleEvents(Geofence: false,Trip: false,Location: true,MovingGeofence: false) { user, error in
                        print(user, error)
//                    }
                    if let listener = roamUser?.locationListener,
                       !listener {
                        print("Roam Toggling listener")
                        Roam.toggleListener(Events: true, Locations: true) { roamUser, error in
                            print(roamUser, error)
                            self?.continueToSession(with: roamUserId, completion: completion)
                        }
                    } else {
                        print("Roam No toggling")
                        self?.continueToSession(with: roamUserId, completion: completion)
                    }
                    }
                }
            }
        } else {
            createUser(completion)
        }
    }
    
    fileprivate func createUser(_ completion: @escaping (Error?) -> Void) {
        Roam.createUser("iOS") { [weak self] roamUser, _ in
            if let roamUserId = roamUser?.userId {
                UserDefaults.standard.set(roamUserId, forKey: "ROAM_USERID")
                print("Roam user created: \(roamUserId)")
                
                print("Roam Toggling events")
                Roam.toggleEvents(Geofence: false,Trip: false,Location: true,MovingGeofence: false){ user, error in
                    print(user, error)
                    
                    Roam.toggleListener(Events: true, Locations: true) { roamUser, error in
                        print(roamUser, error)
                        self?.continueToSession(with: roamUserId, completion: completion)
                    }
                }
            } else {
                print("No roam user created")
            }
        }
    }
    
    fileprivate func continueToSession(with userId: String, completion: @escaping (Error?) -> Void){
        //        createSession?(userId, completion)
        Roam.subscribe(.Location, userId) { [weak self] status, userId, error in
            print("Roam user subscription status: \(status ?? "na")", userId, error)
            self?.startRoamTracking()
        }
    }
    
    fileprivate func startRoamTracking() {
        Roam.setTrackingInAppState(.Foreground)
        Roam.updateLocationWhenStationary(300)
        //        DispatchQueue.main.async {
        let locationData = RoamPublish()
        locationData.location_events = true
        Roam.publishSave(locationData) { status, error in
            print("Roam publish: \(status ?? "na")")
            //                DispatchQueue.main.async {
            Roam.startTracking(.balanced) { tracking, error in
                print("Roam tracking: \(tracking ?? "na")")}
            Roam.updateCurrentLocation(10)
            //                }
            //            }
        }
    }
    
    func stopTracking(completion: @escaping (Error?) -> Void) {
        Roam.stopPublishing()
        Roam.stopTracking() { status, error in
            print("Roam stop tracking: \(status ?? "na"), error: \(error?.message)")
            completion(nil)
        }
    }
    
}

//MARK: - Login Without User
extension RoamHelper {
    
    func toggleEventandListner() {
        print("Roam Toggling events")
        Roam.toggleEvents(Geofence: false,Trip: false,Location: true,MovingGeofence: false){ user, error in
            print(user, error)
            
            Roam.toggleListener(Events: true, Locations: true) { roamUser, error in
                print(roamUser, error)
                self.registerConnector()
            }
        }
    }
    
    func registerConnector() {
        let host: String = "HOST URL"
        let port: UInt16 = 8084  //PORT Number
        let connectionType: RoamMqttConnectionType = .WSS  // Connection Type
        let topic: String = ""  // Publish Topic
        let mqttVersion: String = "" // MQTT version 3.1.1 or 5.0
        let username = "username"
        let password = "password"

        let connector = RoamMqttConnector.Builder(host: host, port: port, connectionType: connectionType, topic: topic)
            .setCredentials(username: username, password: password)
            .setMQTTVersion(mqttVersion)
            .build()
        
        Roam.registerConnector(connector)
    }
    
    func deRegisterConnector() {
        let host: String = "HOST URL"
        let port: UInt16 = 8084  //PORT Number
        let connectionType: RoamMqttConnectionType = .WSS  // Connection Type
        let topic: String = ""  // Publish Topic
        let mqttVersion: String = "" // MQTT version 3.1.1 or 5.0
        let username = "username"
        let password = "password"

        let connector = RoamMqttConnector.Builder(host: host, port: port, connectionType: connectionType, topic: topic)
            .setCredentials(username: username, password: password)
            .setMQTTVersion(mqttVersion)
            .build()
        
        Roam.deRegisterConnector(connector)
        
    }
    
    func startSelfTracking(completion: @escaping (Error?) -> Void) {
        Roam.setTrackingInAppState(.Foreground)
        Roam.updateLocationWhenStationary(300)
        Roam.startTracking(.balanced) { tracking, error in
            print("Roam tracking: \(tracking ?? "na")")
        }
        Roam.updateCurrentLocation(10)
    }
    
}

//MARK: - RoamDelegate

extension RoamHelper: RoamDelegate {
    
    func didUpdateLocation(_ locations: [RoamLocation]) {
        self.locations = locations
        print(locations.last?.location)
    }
    
    func onError(_ error: RoamError) {
        print(error.message)
    }

    //RoamDelegate Method
    func didChangeMQTTStatus(_ status: String) {
        print(status)
        switch status {
        case "connecting":
            break;
        case "connected":
            self.startSelfTracking { error in
                print(error)
            }
        case "disconnected":
            break;
        default:
            break;
        }
    }
}

//MARK: -
extension RoamHelper {
    @objc func applicationDidEnterBackground(_ notification: NSNotification) {
       print("applicationDidEnterBackground")
        Roam.setTrackingInAppState(.Background)

   }
   
   
    @objc func applicationWillForeground(_ notification: NSNotification) {
       print("applicationWillForeground")
        Roam.setTrackingInAppState(.Foreground)
   }
}


extension RoamHelper { //CocoaMQTT5Delegate
//    func mqtt5(_ mqtt5: CocoaMQTT5, didConnectAck ack: CocoaMQTTCONNACKReasonCode, connAckData: MqttDecodeConnAck?) {
//        <#code#>
//    }
//
//    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishMessage message: CocoaMQTT5Message, id: UInt16) {
//        <#code#>
//    }
//
//    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishAck id: UInt16, pubAckData: MqttDecodePubAck?) {
//        <#code#>
//    }
//
//    func mqtt5(_ mqtt5: CocoaMQTT5, didPublishRec id: UInt16, pubRecData: MqttDecodePubRec?) {
//        <#code#>
//    }
//
//    func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveMessage message: CocoaMQTT5Message, id: UInt16, publishData: MqttDecodePublish?) {
//        <#code#>
//    }
//
//    func mqtt5(_ mqtt5: CocoaMQTT5, didSubscribeTopics success: NSDictionary, failed: [String], subAckData: MqttDecodeSubAck?) {
//        <#code#>
//    }
//
//    func mqtt5(_ mqtt5: CocoaMQTT5, didUnsubscribeTopics topics: [String], unsubAckData: MqttDecodeUnsubAck?) {
//        <#code#>
//    }
//
//    func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveDisconnectReasonCode reasonCode: CocoaMQTTDISCONNECTReasonCode) {
//        <#code#>
//    }
//
//    func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveAuthReasonCode reasonCode: CocoaMQTTAUTHReasonCode) {
//        <#code#>
//    }
//
//    func mqtt5DidPing(_ mqtt5: CocoaMQTT5) {
//        <#code#>
//    }
//
//    func mqtt5DidReceivePong(_ mqtt5: CocoaMQTT5) {
//        <#code#>
//    }
//
//    func mqtt5DidDisconnect(_ mqtt5: CocoaMQTT5, withError err: (Error)?) {
//        <#code#>
//    }
    
    func CocoaMqtt_5() {
        ///MQTT 5.0
        let clientID = "CocoaMQTT-" + String(ProcessInfo().processIdentifier)
        let mqtt5 = CocoaMQTT5(clientID: clientID, host: "broker.emqx.io", port: 1883)

        let connectProperties = MqttConnectProperties()
        connectProperties.topicAliasMaximum = 0
        connectProperties.sessionExpiryInterval = 0
        connectProperties.receiveMaximum = 100
        connectProperties.maximumPacketSize = 500
        mqtt5.connectProperties = connectProperties

        mqtt5.username = "test"
        mqtt5.password = "public"
        mqtt5.willMessage = CocoaMQTT5Message(topic: "/will", string: "dieout")
        mqtt5.keepAlive = 60
//        mqtt5.delegate = self
        mqtt5.connect()
    }
    
    func cocoaMqtt_3_1_1() {
        ///MQTT 3.1.1
        let clientID = "CocoaMQTT-" + String(ProcessInfo().processIdentifier)
        let mqtt = CocoaMQTT(clientID: clientID, host: "broker.emqx.io", port: 1883)
        mqtt.username = "test"
        mqtt.password = "public"
        mqtt.willMessage = CocoaMQTTMessage(topic: "/will", string: "dieout")
        mqtt.keepAlive = 60
//        mqtt.delegate = self
        mqtt.connect()
    }
    
    
    
}
