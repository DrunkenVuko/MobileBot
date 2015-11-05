//
//  UseCaseManager.swift
//  iRobot
//
//  Created by Pascal
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

import Foundation
import UIKit

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
    
    /* Instanz unseres Use-Cases */
    let baby = Babysitter()
    
    /** Am Baby */
    static var atBaby = true
    
    /** Im Haus*/
    static var atHome = true
    
    func run() {
        cl.delegate = self
        
        cl.requestAlwaysAuthorization()
        
        nc.addObserver(self, selector: "notification:", name: CustomEvent, object: nil)
        
    }
    
    /**
     * Diese Funktion empfängt die gesendeten Events, und startet in Abhängigkeit der verschiedenen
     * Flags, die entsprechenden UseCases, bzw. beendet diese wieder
     */
    func notification(idh: NSNotification){
        logger.log(.Info, data: idh)
        let str :NSString = (idh.object as? NSString)!
        
            switch str {
                //Tuer Beacon
                case "3000":
                    logger.log(.Info, "3000 ist Beacon: Tuer")
                UseCaseManager.atHome = false
                // Funktion hier...
                break
                
                case "3000" where !UseCaseManager.atHome == true:
                    // Robo soll an die Station...
                break
                
                case "3000" where !UseCaseManager.atHome == false && !UseCaseManager.atBaby == false:
                    // Wenn du aus der Tür bist && nicht am Baby dann -> Action... (homeUC.startAction())
                break
                
                // Baby Beacon
                case "3001":
                    logger.log(.Info, "3001 ist Beacon: Baby")
                break
                
                case "3001" where UseCaseManager.atHome == true:
                    // Wir sind am Baby
                    UseCaseManager.atBaby = true
                    // Aktion...
                break
                
                // Station Beacon
                case "3002":
                    logger.log(.Info, "3002 ist Beacon: Station")
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