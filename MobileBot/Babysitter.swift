//
//  Babysitter.swift
//  MobileBot
//
//  Created by Goran Vukovic on 05.11.15.
//  Copyright © 2015 Goran Vukovic. All rights reserved.
//

import Foundation
import UIKit

/**
 * Diese Klasse dient dem Use Case : Babysitter
 */
class Babysitter: NSObject {
    
    var bc: BotController?;
    var bn: BotNavigator?;
    let bcm = BotConnectionManager.sharedInstance();
    let logger = StreamableLogger();
    var debounceTimer: NSTimer?
    var notification: UILocalNotification?;
    
    static var enterWhileLeave = false;
    
    
    override init() {
        if let bc = bc {
            bn = BotNavigator(controller: bc);
        }
        
        if bcm.connections.count <= 0 {
            Toaster.show("Please provide at minimum a single connection inside the settings.");
        } else {
            if let connection = bcm.connections[0] as? BotConnection {
                bc = BotController(connection: connection);
                
                if let bc = bc {
                    bn = BotNavigator(controller: bc);
                    
                    bcm.connect(connection);
                }
            }
        }
    }
    
    
    /**
     * Startet den Use Case
     *
     */
    func startAction() {
        /*logger.log(.Info, data: "Start GuardHouseWhileUserNotHome!");
        
        scheduleLocalNotification();
        
        UseCaseManager.guibFlag = true;
        UseCaseManager.globalEnter = true;
        
        self.bn?.moveTo(CGPointMake(CGFloat(200), CGFloat(100)), completion: { [weak self] data in
            self?.bc?.scanRange(30, max: 150, inc: 3, callback: { data in
                self?.logger.log(.Info, data: "scanning House entry");
            })
            });
        */
    }
    
    /**
     * Schedules a local notification only once by canceling any previously scheduled notification
     */
    func scheduleLocalNotification() {
        /*
        cancelLocalNotification();
        
        let fireDate = NSDate(timeIntervalSinceNow: 5);
        
        notification = UILocalNotification(title: "Unbefugter Eindringling erkannt", body: "Achtung, es wurde ein unbefugter Eindringling erkannt!", fireDate: fireDate);
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification!);
        
        logger.log(.Info, data: "scheduled local notification with fire date: \(fireDate)");
        */
    }
    
    func cancelLocalNotification() {
        /*
        if let notification = notification {
            UIApplication.sharedApplication().cancelLocalNotification(notification);
            
            logger.log(.Info, data: "canceled previously scheduled notification: \(notification)");
        }
        */
    }
    
    // *****
    // http://stackoverflow.com/questions/28411644/search-as-you-type-swift/28412321#28412321
    // *****
    /**
    * Diese Funktion wird aufgerufen, sobald das End-Event vom Beacon gesendet wurde.
    * Dann wird ein Timer von 20 Sekunden gestartet und erst danach wird die startEndAction()
    * aufgerufen. Wird das End-Event öfter gesendet, startet der Timer von 0 und ruft startEndAction()
    * erst auf, wenn die 20 Sekunden durchlaufen wurden.
    */
    func endAction() {
        
        /*
        GuardHouseWhileUserNotHome.enterWhileLeave = false;
        
        if let timer = debounceTimer {
            timer.invalidate()
        }
        
        debounceTimer = NSTimer(timeInterval: 20.0, target: self, selector: Selector("startEndAction"), userInfo: nil, repeats: false)
        
        NSRunLoop.currentRunLoop().addTimer(debounceTimer!, forMode: "NSDefaultRunLoopMode")
        */
    }
    
    /**
     * Diese Funktion beendet den UseCase und führt entsprechende Operationen durch.
     * Sollte während der 20 Wartesekunden ein Start-Event aufgerufen worden sein, so wird im
     * UseCaseManager die Variable enterWhileLeave auf true gesetzt und der Use Case wird nicht beendet.
     *
     */
    func startEndAction(){
//        if !GuardHouseWhileUserNotHome.enterWhileLeave {
//            
//            cancelLocalNotification();
//            
//            UseCaseManager.ghwunhFlag = false;
//            UseCaseManager.globalEnter=false;
//            
//            self.bc?.stopRangeScan({ [weak self] in
//                self?.bn?.moveTo(CGPointMake(CGFloat(0), CGFloat(0)), completion: nil);
//                })
//            
//            logger.log(.Info, data: "End GuardHouseWhileUserNotHome!")
//        }
    }
    
    deinit {
        logger.log(.Info, data: "++++++");
    }
}