//
//  RaumvermesserViewController.swift
//  MobileBot
//
//  Created by Master on 22.12.15.
//  Copyright © 2015 Goran Vukovic. All rights reserved.
//

import Foundation
class RaumvermesserViewController: NSObject {
    
    var bc: BotController?;
    var bn: BotNavigator?;
    let bcm = BotConnectionManager.sharedInstance();
    let logger = StreamableLogger();
    var debounceTimer: NSTimer?
    var notification: UILocalNotification?;
    
    var startPointX = 10;
    var startPointY = 10;
    
    
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
    
    // Raumvermesser App wird über Button "Vermessen" gestartet
    @IBAction func startMeasure(sender: AnyObject) {
        logger.log(.Info, data: "Start Action Babysitter");
        
        if(alreadyStarted == false){
            //reset();
        }
        reset();
        alreadyStarted = true;
        moveAlongWall();
        
    }
    
    func reset(){
        self.bc?.resetPosition({ () -> Void in
            self.logger.log(.Info, data: "Reset Robo Position");
        });
    }
    
    //gemessene Werte werden in ViewController angezeigt und darauß wird die Fläche berechnet
    @IBAction func saveMeasurment(sender: AnyObject) {
        //TextField mit Längen füllen im RaumvermesserViewController im Storyboard
    }
    
    func moveAlongWall(){
        self.bn?.moveToWithoutObstacle(CGPointMake(CGFloat(startPointX), CGFloat(startPointY)), completion: { data in
            self.logger.log(.Info, data: "start measuring  \(ForwardKinematicsData.x)\(ForwardKinematicsData.y)");
            self.measure(false);
        })
        
    }
    func measure(){
        // in scane Range angegeben über min und max das auf der rechten Seite des Roboters immer ein Hindernis zu erkennen sein soll
        self.bc?.scanRange(<#T##min: UInt8##UInt8#>, max: <#T##UInt8#>, inc: <#T##UInt8#>, callback: { scandata in
            self.logger.log(.Info, data: "scanning room entry \(PingSensorData)");
                    });
            
        self.saveMeasurment();
    }
}