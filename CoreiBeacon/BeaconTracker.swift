//
//  BeaconTracker.swift
//  CoreiBeacon
//
//  Created by Alex Hong on 8/1/18.
//  Copyright © 2018 Alex Hong. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth
import UIKit
import os.log

//MARK: Log functions
class Log {
    static func e(_ message: String) {
        if #available(iOS 10.0, *) {
            os_log("%@", log: OSLog.default, type: .error, message)
        } else {
            print("CoreiBeacon Error: \(message)")
        }
    }
    
    static func d(_ message: String) {
        self.e(message)
    }
}

//MARK: Common UUID

let ESTIMOTE_PROXIMITY_UUID: UUID = UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!
let ESTIMOTE_MACBEACON_PROXIMITY_UUID: UUID = UUID(uuidString: "08D4A950-80F0-4D42-A14B-D53E063516E6")!
let ESTIMOTE_IOSBEACON_PROXIMITY_UUID: UUID = UUID(uuidString: "8492E75F-4FD6-469D-B132-043FE94921D8")!
let SAMPLE_REGION_ID = "EstimoteSampleRegion"

//MARK: CLBeacon Extension
extension CLBeacon {
    var keyString: String {
        return "beaconkey_\(self.major.intValue)-\(self.minor.intValue)"
    }
    func isEqualToCLBeacon(_ beacon: CLBeacon?) -> Bool {
        guard let to = beacon else {
            return false
        }
        
        if self.major.isEqual(to: to.major) && self.minor.isEqual(to: to.minor) {
            return true
        }
        return false
    }
}

//MARK: BeaconTrackerDelegate
@objc protocol BeaconTrackerDelegate: NSObjectProtocol {
    func beaconTracker(_ beaconTracker: BeaconTracker, didChangeNearestBeacon nearestBeacon: CLBeacon?)
    func beaconTracker(_ beaconTracker: BeaconTracker, updateBeacons beacons: [CLBeacon])
    func beaconTrackerNeedToTurnOnBluetooth(_ beaconTracker: BeaconTracker)
}

//MARK: BeaconTracker
class BeaconTracker: NSObject, CLLocationManagerDelegate, CBCentralManagerDelegate {

    //MARK: Singleton Share Beacon Tracker
    static let shared = BeaconTracker()
    
    //MARK: Properties
    private var detectedBeacons: [CLBeacon] = []
    private var blackBeacons: [CLBeacon] = []
    private var nearestBeacon: CLBeacon? = nil
    private var checkTimer: Timer? = nil
    
    private var locationManager: CLLocationManager? = nil
    private var centralManager: CBCentralManager? = nil
    private var beaconRegion: CLBeaconRegion? = nil
    
    var isForegroundMode: Bool {
        return UIApplication.shared.applicationState == .active
    }
    
    //MARK: Delegate
    var delegate: BeaconTrackerDelegate? = nil
    
    //MARK: Initialization
    override init() {
        super.init()
        // register method that be called when the app receive UIApplicationDidEnterBackgroundNotification
        NotificationCenter.default.addObserver(self, selector: #selector(BeaconTracker.applicationEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
    }
    
    //MARK: Start & Stop
    func startBeaconTracking(_ beaconProximityUUID: UUID, regionID beaconRegionID: String) {
        self.locationManager = CLLocationManager()
        
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
        
        // request permission to get location for iOS 8 +
        if self.locationManager!.responds(to: #selector(CLLocationManager.requestAlwaysAuthorization)) {
            self.locationManager?.requestAlwaysAuthorization()
        }
        
        self.locationManager?.delegate = self
        self.locationManager?.pausesLocationUpdatesAutomatically = false
        self.beaconRegion = CLBeaconRegion(proximityUUID: beaconProximityUUID, identifier: beaconRegionID)
        self.locationManager?.startMonitoring(for: self.beaconRegion!)
        self.locationManager?.startUpdatingLocation()
        self.startBeaconRanging()
    }
    
    func stopBeaconTracking() {
        self.stopBeaconRanging()
        if let _ = self.beaconRegion {
            self.locationManager?.stopMonitoring(for: self.beaconRegion!)
        }
        self.locationManager = nil
        self.centralManager = nil
        self.beaconRegion = nil
    }
    
    //MARK: Ranging
    private func startBeaconRanging() {
        self.nearestBeacon = nil
        guard let _ = self.beaconRegion else {
            return
        }
        self.locationManager?.startRangingBeacons(in: self.beaconRegion!)
        self.locationManager?.startUpdatingLocation()
        
        self.checkTimer?.invalidate()
        self.checkTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(BeaconTracker.checkNewButtons), userInfo: nil, repeats: true)
    }
    
    private func stopBeaconRanging() {
        if let _ = beaconRegion {
            locationManager?.stopRangingBeacons(in: beaconRegion!)
        }
        locationManager?.stopUpdatingLocation()
        
        BackgroundTaskManager.shared.endAllBackgroundTasks()
        
        self.checkTimer?.invalidate()
        self.checkTimer = nil
        
        self.nearestBeacon = nil
    }
    
    //MARK: Timer Callback
    @objc private func checkNewButtons() {
        
//        Log.d("didCheckBeacons")
        
        if let _  = self.delegate?.responds(to: #selector(BeaconTrackerDelegate.beaconTracker(_:updateBeacons:))) {
            self.delegate!.beaconTracker(self, updateBeacons: self.detectedBeacons)
        }

        if self.isForegroundMode == false {
            let _ = BackgroundTaskManager.shared.beginNewBackgroundTask()
        }
        
    }
    
    //MARK: CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            Log.d("Location Authorized Always")
        case .authorizedWhenInUse:
            Log.d("Location Authorized When In Use")
        case .denied:
            Log.d("Location Denied")
        case .restricted:
            Log.d("Location Restricted")
        case .notDetermined:
            Log.d("Location Not Determined")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.isEqual(self.beaconRegion) {
            Log.d("Entered Region")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region.isEqual(self.beaconRegion) {
            Log.d("Exited Region")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        Log.e("didRangeBeacons")
        if region.isEqual(self.beaconRegion) {
            
            self.detectedBeacons = beacons
            
            var isChanged = false
            
            if beacons.count == 0 {
                if let _ = self.nearestBeacon {
                    self.nearestBeacon = nil
                    isChanged = true
                }
            }
            else {
                let beacon = beacons[0]
                if beacon.proximity == .near || beacon.proximity == .immediate {
                    if !beacon.isEqualToCLBeacon(self.nearestBeacon) {
                        self.nearestBeacon = beacon
                        isChanged = true
                    }
                }
                else {
                    if let _ = self.nearestBeacon {
                        self.nearestBeacon = nil
                        isChanged = true
                    }
                }
            }
            
            if isChanged {
                if let _  = self.delegate?.responds(to: #selector(BeaconTrackerDelegate.beaconTracker(_:didChangeNearestBeacon:))) {
                    self.delegate!.beaconTracker(self, didChangeNearestBeacon: self.nearestBeacon)
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        Log.d("Beacon raging failed with error: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if region.identifier == self.beaconRegion?.identifier {
            switch state {
            case .inside:
                Log.d("Region Inside State")
            case .outside:
                Log.d("Region Outside State")
            case .unknown:
                Log.d("Region Unknown State")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Log.e("Region monitoring failed with error \(error)")
    }
    
    //MARK: CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            if let _  = self.delegate?.responds(to: #selector(BeaconTrackerDelegate.beaconTrackerNeedToTurnOnBluetooth(_:))) {
                self.delegate!.beaconTrackerNeedToTurnOnBluetooth(self)
            }
        }
    }

    //MARK: Application Observers
    @objc private func applicationEnterBackground() {
        let _ = BackgroundTaskManager.shared.beginNewBackgroundTask()
    }
}

//MARK: BackgroundTaskManager
class BackgroundTaskManager: NSObject {
    
    static let shared = BackgroundTaskManager()
    
    var bgTaskIdList: [UIBackgroundTaskIdentifier] = []
    var masterTaskId: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    func beginNewBackgroundTask() -> UIBackgroundTaskIdentifier {
        
        let application = UIApplication.shared
        var bgTaskId: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
        
        if application.responds(to: #selector(UIApplication.beginBackgroundTask(withName:expirationHandler:))) {
            bgTaskId = application.beginBackgroundTask(expirationHandler: {
                [weak self] in
                Log.d("background task \(bgTaskId) expired")
                guard let index = self?.bgTaskIdList.index(of: bgTaskId) else {
                    Log.e("Invaild Task \(bgTaskId)")
                    return
                }
                application.endBackgroundTask(bgTaskId)
                self?.bgTaskIdList.remove(at: index)
            })
            
            if self.masterTaskId == UIBackgroundTaskInvalid {
                self.masterTaskId = bgTaskId
                Log.d("start master task \(bgTaskId)")
            }
            else {
                Log.d("started background task \(bgTaskId)")
                self.bgTaskIdList.append(bgTaskId)
                self.endBackgroundTasks()
            }
        }
        return bgTaskId
    }
    
    func endBackgroundTasks() {
        self.drainBGTaskList(all: false)
    }
    
    func endAllBackgroundTasks() {
        self.drainBGTaskList(all: true)
    }
    
    func drainBGTaskList(all: Bool) {
        let application = UIApplication.shared
        if application.responds(to: #selector(UIApplication.endBackgroundTask(_:))) {
            let count = self.bgTaskIdList.count
            for _ in (all ? 0 : 1) ..< count {
                let bgTaskId = self.bgTaskIdList[0]
                Log.d("ending background task with id\(bgTaskId)")
                application.endBackgroundTask(bgTaskId)
                self.bgTaskIdList.remove(at: 0)
            }
            
            if self.bgTaskIdList.count > 0 {
                Log.d("kept background task id \(self.bgTaskIdList[0])")
            }
            
            if all {
                Log.d("no more background tasks running")
                application.endBackgroundTask(self.masterTaskId)
                self.masterTaskId = UIBackgroundTaskInvalid
            }
            else {
                Log.d("kept master background task id \(self.masterTaskId)")
            }
        }
    }
}

