//
//  beaconSettings.swift
//  Beacon_Framework
//
//  Created by Goran Vukovic on 25.11.15.
//  Copyright © 2015 Goran Vukovic. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit


@objc protocol beaconSettingsProtocol {
    func rangedBeacons(beacons: [AnyObject])
    optional func didDetermineState(state: CLRegionState)
    optional func didEnterRegion(region: CLRegion)
    optional func didExitRegion(region: CLRegion, major: Int)
}

@objc class beaconSettings: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    var beaconRegion = CLBeaconRegion()
    var proximityUUID = NSUUID()
    var delegate: beaconSettingsProtocol?
    var recentMajor: Int?
    
    init(proximityUUID: NSUUID?) {
        super.init()
        if (proximityUUID != nil) {
            self.proximityUUID = proximityUUID!
        }
        if(locationManager.respondsToSelector("requestAlwaysAuthorization")) {
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = false
        beaconRegion = CLBeaconRegion(proximityUUID: proximityUUID!, identifier: "beaconmanager") // beaconmanager
        beaconRegion.notifyEntryStateOnDisplay = true
        locationManager.startMonitoringForRegion(beaconRegion)
    }
    
    // Beacon Delegates -- responding to region events
    func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        // tells the delegate that the new region is being monitored
        locationManager.requestStateForRegion(beaconRegion)
        print(beaconRegion)
    }
    
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        print("Error: monitoringDidFailForRegion")
    }
    
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        self.delegate?.didDetermineState!(state)
        switch state {
        case .Inside:
            print("State: You are Inside")
            locationManager.startRangingBeaconsInRegion(region as! CLBeaconRegion)
        case .Outside:
            return
        default:
            locationManager.stopRangingBeaconsInRegion(region as! CLBeaconRegion)
        }
    }
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("entered region \(region)")
        self.delegate?.didEnterRegion!(region)
    }
    
    func locationManager(manager: CLLocationManager,didExitRegion region: CLRegion){
        print("exited region \(region)")
        self.delegate?.didExitRegion!(region, major: recentMajor!)
        self.recentMajor = nil
    }
    
    // Beacon Delegates -- responding to ranging events
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        //print("Found \(beacons.count) beacons")
        //print("Major: \(beacons[0].major), Minor: \(beacons[0].minor), Proximity: \(beacons[0].proximity.rawValue), Accuracy: \(beacons[0].accuracy)")
        
        if (beacons.count > 0) {
            var goodBeacons: Array<CLBeacon> = []
            for b in beacons {
                //print("Major: \(beacons[0].major), Minor: \(beacons[0].minor), Proximity: \(beacons[0].proximity.rawValue), Accuracy: \(beacons[0].accuracy)")
                if (b.proximity == CLProximity.Unknown)
                {
                    //print("Nix", b.minor)
                } else if (b.proximity == CLProximity.Immediate)
                {
                    //print("Nah", b.minor)
                    
                } else if (b.proximity == CLProximity.Near)
                {
                    //print("Mittel", b.minor)
                    
                } else if (b.proximity == CLProximity.Far)
                {
                    //print("Fern", b.minor)
                    
                }
                
                if (b.accuracy > 0) {
                    goodBeacons.append(b)
                }
            }
            
            
            if (goodBeacons.count > 0) {
                self.recentMajor = goodBeacons.first?.major as? Int
                self.delegate?.rangedBeacons(goodBeacons)
            }
            
        }
        
    }
}