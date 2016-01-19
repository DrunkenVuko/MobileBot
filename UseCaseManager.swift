//
//  UseCaseManager.swift
//  iRobot
//
//  Created by Pascal
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

/**
 * Diese Klasse dient dem Eventmanagement der Beacons bzw. UseCases.
 * Die Flags dienen dem Eventhandling und sind dafür zuständig, dass immer nur 
 * 1 Use Case durchlaufen werden kann (ist momentan so programmiert, kann aber leicht 
 * geändert werden, um bspw. 2 Use Cases gleichzeitig laufen zu lassen)""""
 */
class UseCaseManager : NSObject, CLLocationManagerDelegate {
    
    private static var instance: UseCaseManager?
        
    let nc = NSNotificationCenter.defaultCenter()
    let cl = CLLocationManager()
    var beaconRegion: CLBeaconRegion?
    let logger = StreamableLogger()
    
    /* Am Baby */
    static var atBaby = true
    
    /* Im Haus */
    static var atHome = true
    
    /* Wache */
    static var atStation = true
    
    func run() {
        cl.delegate = self
        
        cl.requestAlwaysAuthorization()
        
        //nc.addObserver(self, selector: "notification:", name: CustomEvent, object: nil)
        
    }
    
    /**
     * Diese Funktion empfängt die gesendeten Events, und startet in Abhängigkeit der verschiedenen
     * Flags, die entsprechenden UseCases, bzw. beendet diese wieder
     */
    func notification(idh: NSNotification){
        logger.log(.Info, data: idh)
        let str :NSString = (idh.object as? NSString)!
        
            switch str {
                /* Beacon Babysitter
                Door Exit   - 3010
                Door Entry  - 3011
                At Baby     - 3020
                Not at baby - 3021
                Station     - 3030
                */
                
                // Aus dem Haus raus...
                case "3010":
                    logger.log(.Info, data: "3010 ist Beacon: Not at Home")
                    UseCaseManager.atHome = false
                    
                    if(UseCaseManager.atHome == true)
                    {
                        // Robo soll an die Station...
                    }
                    else if(UseCaseManager.atHome == false && UseCaseManager.atBaby == false)
                    {
                        UseCaseManager.atStation = false
                        // Wenn du aus der Tür bist && nicht am Baby dann -> Action... (homeUC.startAction())
                    }
                break
                
                // Ins Haus rein...
                case "3011":
                    logger.log(.Info, data: "3011 ist Beacon: At Home")
                    UseCaseManager.atHome = true
                break
                
                // Baby Beacon
                
                // Am Baby
                case "3020":
                    logger.log(.Info, data: "3020 ist Beacon: At Baby")
                    
                    // Wir sind am Baby
                    UseCaseManager.atBaby = true
                    // Aktion...
                    if(UseCaseManager.atHome == true)
                    {
                        
                    }
                break
                
            case "4010":
                
                logger.log(.Info, data: "4010 ist Beacon: Not Home")
                
                
                
                break
                
                
                
                // Station Beacon
                
            case "4020":
                
                logger.log(.Info, data: "4020 ist Beacon: Home")
                
                break
                
                
                
            default:
                
                logger.log(.Info, data: "No known Event!")
                
                return
            }
    }
    
    /** Singleton */
    static func sharedInstance() -> UseCaseManager {
        if UseCaseManager.instance == nil {
            UseCaseManager.instance = UseCaseManager()
        }
        
        return UseCaseManager.instance!
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        logger.log(.Info, data: "✝ (rip) ✝")
    }
}