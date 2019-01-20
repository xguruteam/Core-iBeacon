//
//  ViewController.swift
//  CoreiBeacon
//
//  Created by Alex Hong on 8/1/18.
//  Copyright © 2018 Alex Hong. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, BeaconTrackerDelegate {
    func beaconTracker(_ beaconTracker: BeaconTracker, updateBeacons beacons: [CLBeacon]) {
        
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        BeaconTracker.shared.delegate = self
        BeaconTracker.shared.startBeaconTracking(ESTIMOTE_PROXIMITY_UUID, regionID: SAMPLE_REGION_ID)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func beaconTracker(_ beaconTracker: BeaconTracker, didChangeNearestBeacon nearestBeacon: CLBeacon?) {
        if let _ = nearestBeacon {
            Log.e(nearestBeacon!.keyString)
        }
        else {
            Log.e("no beacon")
        }
    }
    
    func beaconTrackerNeedToTurnOnBluetooth(_ beaconTracker: BeaconTracker) {
        let alertController = UIAlertController(title: "Turn On Bluetooth", message: "Please turn on Bluetooth for iBeacon Monitoring", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}

