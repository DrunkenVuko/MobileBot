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
    var nearBeacon: CLBeacon!
    var beaconLastSeen: NSMutableDictionary!

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
        beaconLastSeen = NSMutableDictionary()
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
    func getNear(beacons: [CLBeacon])
    {
        var beacon: CLBeacon = CLBeacon()
        
        if(beacons[0].proximity.rawValue < beacons[1].proximity.rawValue && beacons[0].proximity.rawValue < beacons[2].proximity.rawValue)
        {
            beacon = beacons[0] 
        }
        else if(beacons[1].proximity.rawValue < beacons[0].proximity.rawValue && beacons[1].proximity.rawValue < beacons[2].proximity.rawValue)
        {
            beacon = beacons[1] 
        }
        else
        {
            beacon = beacons[2]
        }
        nearBeacon = beacon
    }
    
    // Beacon Delegates -- responding to ranging events
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        //print("Found \(beacons.count) beacons")
        //print("Major: \(beacons[0].major), Minor: \(beacons[0].minor), Proximity: \(beacons[0].proximity.rawValue), Accuracy: \(beacons[0].accuracy)")
        
        getNear(beacons)
        
        if (beacons.count > 0) {
            var goodBeacons: Array<CLBeacon> = []
            for b in beacons {
                //print("Major: \(b.major), Minor: \(b.minor), Proximity: \(b.proximity.rawValue), Accuracy: \(b.accuracy)")
                if (b.proximity == CLProximity.Unknown)
                {
                    //print("Nix - Beacon: ", b.minor)
                } else if (b.proximity == CLProximity.Immediate)
                {
                    //print("Nah - Beacon: ", b.minor)
                    
                } else if (b.proximity == CLProximity.Near)
                {
                    //print("Mittel - Beacon: ", b.minor)
                    
                } else if (b.proximity == CLProximity.Far)
                {
                    //print("Fern - Beacon: ", b.minor)
                    
                }
                
                if (b.accuracy > 0) {
                    goodBeacons.append(b)
                }
            }
            
            
        for beacon in beacons {
            var shouldSendNotification: Bool  = false
            var now: NSDate = NSDate()
            var beaconKey: NSString = String(beacon.minor)
            NSLog("Ranged UUID: %@ Major:%ld Minor:%ld RSSI:%ld", beacon.proximityUUID.UUIDString, beacon.major, beacon.minor, beacon.rssi)
            
            if beaconLastSeen.objectForKey(beaconKey) == nil {
                NSLog("This beacon has never been seen before")
                shouldSendNotification = true;
                beaconLastSeen.objectForKey(beaconKey)?.setValue("found", forKey: beaconKey as String)
                print("if Key : ", beaconLastSeen.objectForKey(beaconKey))
                print(now)
            }
            else {
                print("else Key : ", beaconLastSeen.objectForKey(beaconKey))
                var lastSeen: NSDate = NSDate()
                lastSeen.setValue(beaconLastSeen.objectForKey(beaconKey), forKey: String(lastSeen.timeIntervalSinceNow))
                
                var secondsSinceLastSeen: NSTimeInterval  = now.timeIntervalSinceDate(lastSeen)
                NSLog("This beacon was last seen at %@, which was %.0f seconds ago", lastSeen, secondsSinceLastSeen);
                if (secondsSinceLastSeen < 3600*24 /* one day in seconds */) {
                    shouldSendNotification = true;
                }
            }
            
//            if (shouldSendNotification) {
//                [self sendLocalNotification];
//            }
        }
            
            if (goodBeacons.count > 0) {
                self.recentMajor = goodBeacons.first?.major as? Int
                self.delegate?.rangedBeacons(goodBeacons)
            }
            
        }
        
    }
}