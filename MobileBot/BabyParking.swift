//
//  BabyParking.swift
//  MobileBot
//
//  Created by Bianca Baier on 20.01.16.
//  Copyright © 2016 Goran Vukovic. All rights reserved.
//

import Foundation

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
class BabyParking: UIViewController {
    
    // Point coordinates
    
    let STATION_POINT: (Float, Float) = (0, 0)
    
    let POINT_1: (Float, Float) = (0, 0)
    let POINT_2: (Float, Float) = (0, 100)
    
    var bc: BotController?;
    var bn: BotNavigator?;
    let bcm = BotConnectionManager.sharedInstance();
    let logger = StreamableLogger();
    
    var stopped = false
    var someoneAtDoor: Bool = false
    
    var parkingLotSize: Int32 = 20
    
    var positiondata: (Float, Float, Float) = (0, 0, 0)
    var parkStart: (Float, Float, Float) = (0, 0, 0)
    var inParkingLot = false
    
    
    
    @IBAction func start(sender: AnyObject) {
        self.startAction()
    }
    
    @IBAction func stop(sender: AnyObject) {
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
    
    /**
     * Sends the roboter from one street point to the other
     * Scans for empty parking lots in between
     */
    func patrol(back: Bool){
        
        var coordinate = self.POINT_2
        var angle:UInt8 = 0
        
        if(back){
            self.logger.log(.Info, data: "babybot: MOVE back");
            coordinate = self.POINT_1
            angle = 180
            
        } else {
            self.logger.log(.Info, data: "babybot: MOVE forth");
        }
        
        self.moveToWithScan(CGPointMake(CGFloat(coordinate.0), CGFloat(coordinate.1)), scanAngle: angle, completion: { data in
            self.logger.log(.Info, data: "babybot: point reached.");
            
            // unless stop was called, go to next streetpoint
            if(!self.stopped){
                self.patrol(!back)
            }
        })
        
    }
    
    
    

    
    /**
     * Starts patroling
     */
    func startAction() {
        self.stopped = false
        goToDoor()
    }
    
    /**
     * Makes roboter stop on the next street point
     */
    func stopAction() {
        self.stopped = true
    }
    
    /**
     * Remove notification observer at the end
     */
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    /**
    * Diese Bewegungs-Funktion dient dem ParkingBot Use Case
    **/
    func moveToWithScan(point: CGPoint, scanAngle: UInt8, completion: ((ForwardKinematicsData) -> ())? ) {
        self.bc?.stopRangeScan({
            self.bc?.stopMovingWithPositionalUpdate({
                self.logger.log(.Info, data: "\(point)");
                
                self.bc?.startUpdatingPosition(true, completion: { data in
                    self.logger.log(.Info, data: "current position: \(data)");
                    
                    // Wenn der Roboter bereits im Zielrechteck ist, soll er nicht starten
                    // Berechnung des Rechtecks um den Zielpunkt
                    let dest = CGRectMake(point.x, point.y, 0, 0);
                    let destWithInset = CGRectInset(dest, -1.0, -1.0);
                    let currentPoint = CGPointMake(CGFloat(data.x), CGFloat(data.y));
                    let destReached = CGRectContainsPoint(destWithInset, currentPoint);
                    
                    
                    if destReached {
                        self.destinationReached(completion);
                        self.logger.log(.Info, data: "**** Already in destination area ****");
                        
                    } else {
                        
                        let angle = atan2f(Float(point.y) - data.y, Float(point.x) - data.x);
                        let degrees = angle * 180 / 3.14;
                        
                        // Roboter dreht sich in die richtige Richtung
                        self.bn?.turnToAngle(degrees, speed: (self.bn?.speed)!, completion: { data in
                            let startingPoint = CGPointMake(CGFloat(data.x), CGFloat(data.y));
                            var previousDistance = BotUtils.distance(from: startingPoint, to: point);
                            let dest = CGRectMake(point.x, point.y, 0, 0);
                            let destWithInset = CGRectInset(dest, -1.0, -1.0);
                            
                            self.logger.log(.Info, data: "computed destination area: \(destWithInset), from point: \(point)");
                            
                            self.bc?.startMovingWithPositionalUpdate((self.bn?.speed)!, omega: 0, callback: { data in
                                self.positiondata = data
                                // Berechnung des Rechtecks um den Zielpunkt
                                let angle = atan2f(Float(point.y) - data.y, Float(point.x) - data.x);
                                let degrees = angle * 180 / 3.14;
                                let currentPoint = CGPointMake(CGFloat(data.x), CGFloat(data.y));
                                let currentDistance = BotUtils.distance(from: point, to: currentPoint);
                                
                                self.logger.log(.Info, data: "****************************************************************************");
                                self.logger.log(.Info, data: "moving forward: \(data) :: \(point)");
                                self.logger.log(.Info, data: "angle to point: \(degrees)");
                                self.logger.log(.Info, data: "current distance: \(currentDistance), previous distance: \(previousDistance)");
                                self.logger.log(.Info, data: "destination area: \(destWithInset), current point: \(currentPoint)");
                                
                                let destReached = CGRectContainsPoint(destWithInset, currentPoint);
                                
                                if destReached {
                                    self.destinationReached(completion);
                                    
                                } else if currentDistance > previousDistance {
                                    self.destinationReached(completion);
                                }
                                
                                previousDistance = currentDistance;
                            });
                            
                            // flag welches verhindern soll dass ein Hindernis vom Roboter wahrgenommen wird, wenn keines vorhanden ist
                            // es muss mehrere male hintereinander vom Roboter gesendet werden, dass sich etwas vor ihm befindet
                            var scanBugFlag = 0.0
                            
                            self.bc?.scanRange(scanAngle, max: scanAngle, inc: 0, callback: { scandata in
                                self.logger.log(.Info, data: "DISTANCE: \(scandata.pingDistance)");
                                self.logger.log(.Info, data: "BUGFLAG: \(scanBugFlag)");
                                
                                if(scandata.pingDistance > 0 && scandata.pingDistance < 35) {

                                    if(scanBugFlag >= 5.0){
                                        self.logger.log(.Info, data: "BabyParking: intruder detected");
                                        
                                        
                                        //self.inParkingLot = true
                                        self.someoneAtDoor = true
                                        
                                        self.bc?.stopRangeScan({
                                            self.bc?.stoptUpdatingPosition();
                                            self.bc?.stop({
                                                //self.goToStation();
                                                
                                                
                                            });
                                        });

                                        
                                        
                                        //self.parkStart = self.positiondata
                                        
                                        self.sendAlarm("Alarm!");
                                        
                                    }else{
                                        scanBugFlag++
                                    }
                            
                                    
                                } else {
                                    scanBugFlag = 0.0
                                }
                            });
                        });
                    }
                });
            });
        })
    }
    
    // der Roboter hat seine Zielposition erreicht. Es wird die Endaktion ausgeführt
    func destinationReached(completion: ((ForwardKinematicsData) -> ())?) {
        self.bc?.stopMovingWithPositionalUpdate({
            self.bc?.startUpdatingPosition(true, completion: { data in
                self.logger.log(.Info, data: "destination reached: \(CGPointMake(CGFloat(data.x), CGFloat(data.y)))");
                completion?(data);
            });
        });
        
        self.bc?.stopRangeScan({});
        
    }
    
    func goToStation(){
        
        self.bn?.setTurnSpeed(20)
        self.bn?.setSpeed(20)
        self.bn?.moveToWithoutObstacle(CGPointMake(CGFloat(STATION_POINT.0), CGFloat(STATION_POINT.1)), completion: { data in
            self.logger.log(.Info, data: "baby: MOVE TO Station finished");
            
            self.sendAlarm("Robo at Station");
        })
        
    }
    
    func goToDoor(){
        self.logger.log(.Info, data: "goToDoor");
        
        //zuerst zur linkem tuerrand fahren
        /*self.bn?.moveToWithoutObstacle(CGPointMake(CGFloat(POINT_1.0), CGFloat(POINT_1.0)), completion: { data in
        self.logger.log(.Info, data: "baby: MOVE TO doorpoint LEFT finished");
        //beginnend von links nach rechts zu patroullieren
        self.alarm
        self.patrol(false);
        
        })*/
        
        self.patrol(false)
        
        
    }
    
    func sendAlarm(message: String){
        Toaster.show(message);
    }
    
}
