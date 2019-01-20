//
//  BeaconTableViewController.swift
//  CoreiBeacon
//
//  Created by Alex Hong on 8/2/18.
//  Copyright © 2018 Alex Hong. All rights reserved.
//

import UIKit
import CoreLocation

class BeaconTableViewController: UITableViewController, BeaconTrackerDelegate {
    
    var beacons: [CLBeacon] = []
        
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        BeaconTracker.shared.delegate = self
        BeaconTracker.shared.startBeaconTracking(ESTIMOTE_PROXIMITY_UUID, regionID: SAMPLE_REGION_ID)
    }

    func beaconTracker(_ beaconTracker: BeaconTracker, didChangeNearestBeacon nearestBeacon: CLBeacon?) {
        if let _ = nearestBeacon {
            Log.e(nearestBeacon!.keyString)
            let notfication = UILocalNotification()
            notfication.alertBody = "New Beacon Dectected"
            notfication.alertAction = nearestBeacon!.proximityUUID.uuidString
            notfication.soundName = UILocalNotificationDefaultSoundName
            UIApplication.shared.presentLocalNotificationNow(notfication)
        }
        else {
            Log.e("no beacon")
        }
    }
    
    func beaconTracker(_ beaconTracker: BeaconTracker, updateBeacons beacons: [CLBeacon]) {
        self.beacons = beacons
        tableView.reloadData()
    }
    
    func beaconTrackerNeedToTurnOnBluetooth(_ beaconTracker: BeaconTracker) {
        let alertController = UIAlertController(title: "Turn On Bluetooth", message: "Please turn on Bluetooth for iBeacon Monitoring", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.beacons.count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let aci = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        view.addSubview(aci)
        aci.startAnimating()
        return view
    }
//    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return "Detecting..."
//    }
//
//    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
//        view.addSubview(UIActivityIndicatorView(activityIndicatorStyle: .gray))
//    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")

        // Configure the cell...
        let index = indexPath.row
        let beacon = self.beacons[index]
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "reuseIdentifier")
        }
        
        cell!.textLabel?.text = "\(beacon.major.intValue)-\(beacon.minor.intValue)"
        cell!.detailTextLabel?.text = beacon.proximityUUID.uuidString
        cell!.imageView?.image = UIImage(named: "AppIcon")

        return cell!
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
}
