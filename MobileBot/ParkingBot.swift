//
//  ParkingBot.swift
//  MobileBot
//
//  Created by Betty van Aken on 17.12.15.
//  Copyright © 2015 Goran Vukovic. All rights reserved.
//

import UIKit

/**
 * Diese Klasse dient dem Use Case : ParkingBot
 */
class ParkingBot: UIViewController {
    
    // Street coordinates
    internal static let STREET_POINT_1: (CGFloat, CGFloat) = (0, 0)
    internal static let STREET_POINT_2: (CGFloat, CGFloat) = (100, 0)
    
    var bc: BotController?;
    var bn: BotNavigator?;
    let bcm = BotConnectionManager.sharedInstance();
    let logger = StreamableLogger();
    
    var stopped = false
    
    @IBAction func startPressed(sender: AnyObject) {
        self.startAction()
    }
    
    @IBAction func stopPressed(sender: AnyObject) {
        self.stopAction()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        createConnection()
        bc?.resetPosition(nil);
    }
    
    /**
     * Looks for connections in BotConnectionManager
     * Creates BotController and BotNavigator for the connection and calls connect() on BotConnectionManager
     **/
    func createConnection(){
        if bcm.connections.count <= 0 {
            Toaster.show("Please provide at minimum a single connection inside the settings.");
        } else {
            if let connection = bcm.connections[0] as? BotConnection {
                bc = BotController(connection: connection);
                
                if let bc = bc {
                    bn = BotNavigator(controller: bc);
                }
                bcm.connect(connection);
            }
        }
    }
    
    /**
     * Checks if BotConnection is initialized and connected
     **/
    func isConnected() -> Bool {
        let connectedStatus: BotConnectionConnectionStatus = .Connected
        return (bc?.connectionStatus == connectedStatus)
    }
    
    func scan() {
        // scanBugFlag = flag to make sure not one single "buggy" value was send
        // value of zero distance (== empty space) must be sent 5 times in a row
        
        var scanBugFlag = 0.0;
        
        // scan with a fixed angle of 0°
        self.bc?.scanRange(0, max: 0, inc: 0, callback: { scandata in

            self.logger.log(.Info, data: "scanning parking lot \(scandata.pingDistance)");
            
            if(scandata.pingDistance == 0) {
                if(scanBugFlag >= 5.0){
                    self.logger.log(.Info, data: "empty parkinglot detected");
                    
                    self.sendAlarm("Empty Parkinglot!");
                    
                }else {
                    scanBugFlag++;
                }
            }else {
                scanBugFlag = 0.0;
            }
        })
    }
    
    func patrol(back: Bool){
        
        var coordinate = ParkingBot.STREET_POINT_2
        
        if(back){
            self.logger.log(.Info, data: "parkingbot: MOVE back");
            coordinate = ParkingBot.STREET_POINT_1
            
        } else {
            self.logger.log(.Info, data: "parkingbot: MOVE forth");
        }
        
        self.scan();
        
        self.bn?.moveToWithoutObstacle(CGPointMake(coordinate.0, coordinate.1), completion: { data in
            self.logger.log(.Info, data: "parkingbot: streetpoint reached.");
            
            self.patrol(!back)
        })
        
    }
    
    func patrolWithInternalScan(back: Bool){
        
        var coordinate = ParkingBot.STREET_POINT_2
        
        if(back){
            self.logger.log(.Info, data: "parkingbot: MOVE back");
            coordinate = ParkingBot.STREET_POINT_1
            
        } else {
            self.logger.log(.Info, data: "parkingbot: MOVE forth");
        }
        
        self.bn?.moveToWithScan(CGPointMake(coordinate.0, coordinate.1), completion: { data in
            self.logger.log(.Info, data: "parkingbot: streetpoint reached.");
            
            if(!self.stopped){
                self.patrol(!back)
            }
        })
        
    }
    
    //spaeter mal mit push nachrichten umsetzen
    //@TODO
    func sendAlarm(message: String){
        Toaster.show(message);
    }
    
    
    /**
     * Startet den Use Case
     */
    func startAction() {
        patrol(false)
    }
    
    /**
     * Startet den Use Case
     */
    func stopAction() {
        self.stopped = true
    }

}