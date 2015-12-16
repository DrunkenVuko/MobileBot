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
    
    //let bathUC = GuardUserInBath();
    /** Guard User in Bath flag */
    static var guibFlag = false;
    
    //let homeUC = GuardHouseWhileUserNotHome();
    /** Guard house while user not home flag */
    static var ghwunhFlag = false;
    
    //let weatherUC = WarnUserIfWeatherAlarm();
    /** Warn User if weather alarm flag */
    static var wuiwaFlag = false;
    
    /** Global Enter flag für Eventhandling */
    static var globalEnter = false;
    
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
                //Startet Guard House While User Not Home
                case "3020" where !UseCaseManager.globalEnter && !UseCaseManager.ghwunhFlag:
                    print("Case 3020 - At Baby")
                    //homeUC.startAction();
                    UseCaseManager.guibFlag = true;
                    UseCaseManager.globalEnter = true;
           
                //Flag wird gesetzt für den Fall, falls das iBeacon ein beenden Event sendet und dann wieder ein Start Event,
                // obwohl beides nicht gesendet werden dürfte
                case "3021" where UseCaseManager.globalEnter && UseCaseManager.ghwunhFlag:
                    print("Case 3021 - Not At Baby")
                    UseCaseManager.guibFlag = false;
                    UseCaseManager.globalEnter = false;
                    //GuardHouseWhileUserNotHome.enterWhileLeave = true;
                
                //Beendet Guard House While User Not Home
                case "1337" where UseCaseManager.ghwunhFlag:
                    print("")
                    //homeUC.endAction();
                
                //Startet Guard User In Bath
            case "1338" where !UseCaseManager.globalEnter && !UseCaseManager.guibFlag:
                print("")
                    //bathUC.startAction();
                
                //Flag wird gesetzt für den Fall, falls das iBeacon ein beenden Event sendet und dann wieder ein Start Event,
                // obwohl beides nicht gesendet werden dürfte
            case "1338" where UseCaseManager.globalEnter && UseCaseManager.guibFlag:
                print("")
                    //GuardUserInBath.enterWhileLeave = true;
                
                //Beendet Guard User In Bath
            case "1339" where UseCaseManager.guibFlag:
                print("")
                    //bathUC.endAction();
                /* Beacon als Wetter Event einsetzen: */
            case "1340" where !UseCaseManager.globalEnter && !UseCaseManager.wuiwaFlag:
                print("")
                    //weatherUC.startAction()
                
                default:
                    logger.log(.Info, data: "No known Event!");
                    return;
            }
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