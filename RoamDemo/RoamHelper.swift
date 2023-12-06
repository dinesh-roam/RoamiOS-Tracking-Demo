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
//        #error("Add Publish Key")
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

//MARK: - RoamDelegate

extension RoamHelper: RoamDelegate {
    
    func didUpdateLocation(_ locations: [RoamLocation]) {
        self.locations = locations
        print(locations.last?.location)
    }
    
    func onError(_ error: RoamError) {
        print(error.message)
    }
    
    @objc func applicationDidEnterBackground(_ notification: NSNotification) {
       print("applicationDidEnterBackground")
        Roam.setTrackingInAppState(.Background)

   }
   
   
    @objc func applicationWillForeground(_ notification: NSNotification) {
       print("applicationWillForeground")
        Roam.setTrackingInAppState(.Foreground)
   }

}
