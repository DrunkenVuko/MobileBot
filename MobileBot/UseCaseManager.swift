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
 * geändert werden, um bspw. 2 Use Cases gleichzeitig laufen zu lassen)
 */
class UseCaseManager : NSObject, CLLocationManagerDelegate {
    
    private static var instance: UseCaseManager?;
        
    let nc = NSNotificationCenter.defaultCenter();
    let cl = CLLocationManager();
    var beaconRegion: CLBeaconRegion?;
    let logger = StreamableLogger();
    
    //let babySitterUC = Babysitter();

    // Kontrollvariablen
    //-------------------
    // Der Benutzer ist per Default im Haus
    static var atHome = false
    
    // Der Benutzer ist per Default nicht am Baby
    static var atBaby = false
    
    // Der Roboter soll nur 1x aufgerufen werden
    static var robotRunning = false
    
    // Doppelte Nachrichten sind Tabu
    static var alreadyPushed = false
    
    func run() {
        cl.delegate = self;
        
        cl.requestAlwaysAuthorization();
        
        nc.addObserver(self, selector: "notification:", name: CustomEvent, object: nil);
        
    }
    
    /**
     * Diese Funktion empfängt die gesendeten Events, und startet in Abhängigkeit der verschiedenen
     * Flags, die entsprechenden UseCases, bzw. beendet diese wieder
     */
    func notification(idh: NSNotification){
        logger.log(.Info, data: idh);
        let str :NSString = (idh.object as? NSString)!;
        switch str {
            /* Beacon Babysitter
            Door Exit   - 3010
            Door Entry  - 3011
            At Baby     - 3020
            Not at baby - 3021
            */
            
            /*************************************************************************************************/
            /***** - Fall: Haus betreten / verlassen *********************************************************/
            /*************************************************************************************************/
            
            // Wird beim Verlassen des Beacons aktiviert
        case "3010" where UseCaseManager.robotRunning == false && UseCaseManager.atHome == true && UseCaseManager.atBaby == false:
            printLog("3010 ist Beacon: Ich bin aus dem Haus raus - Roboter startet nun")
            
            // 1) Funktion des Robos starten
            // 2) atHome auf false setzen
            // 3) robotRunning beim Start auf true setzen
            
            //UseCaseManager.atHome = false
            //UseCaseManager.robotRunning = true
            break
            
            // Wird beim Betreten des Beacons aktiviert
        case "3011" where UseCaseManager.robotRunning == true && UseCaseManager.atHome == false && UseCaseManager.atBaby == false:
            printLog("3011 ist Beacon: Ich bin wieder im Haus  - Roboter faehrt wieder zur Station")
            
            // 1) Funktion zum Beenden des Robos aufrufen
            // 2) atHome auf true setzen
            // 3) robotRunning auf false setzen
            
            //UseCaseManager.atHome = true
            //UseCaseManager.robotRunning = false
            break
            
            
            /*************************************************************************************************/
            /***** - Fall: Baby betreten / verlassen *********************************************************/
            /*************************************************************************************************/
            
            // Wird beim Betreten des Beacons aktiviert
        case "3020" where UseCaseManager.robotRunning == false && UseCaseManager.atHome == true && UseCaseManager.atBaby == false:
            printLog("3020 ist Beacon: Ich bin am Baby")
            
            // 1) Funktion zum Beenden des Robos aufrufen
            // 2) atBaby auf true setzen

            UseCaseManager.atBaby = true
            break
            
            // Wird beim Verlassen des Beacons aktiviert
        case "3021" where UseCaseManager.robotRunning == false && UseCaseManager.atHome == true && UseCaseManager.atBaby == true:
            printLog("3020 ist Beacon: Ich bin nicht mehr am Baby")
            
            // 1) Funktion zum Beenden des Robos aufrufen
            // 2) atBaby auf false setzen

            UseCaseManager.atBaby = false
            break

        default:
            logger.log(.Info, data: "No known Event!")
            return
        }
    }
    
    
    func printLog(var temp: String)
    {
        print("/******************************************************************************************/")
        print(temp)
        print("/******************************************************************************************/")
    }
    
    /** Singleton */
    static func sharedInstance() -> UseCaseManager {
        if UseCaseManager.instance == nil {
            UseCaseManager.instance = UseCaseManager();
        }
        
        return UseCaseManager.instance!;
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self);
        
        logger.log(.Info, data: "✝ (rip) ✝");
    }
}