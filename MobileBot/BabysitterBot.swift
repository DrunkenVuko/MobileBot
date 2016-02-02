//
//  BabysitterBot.swift
//  MobileBot
//
//  Created by Bianca Ciuperca-Baier, Leonie Wismeth, Goran Vukovic on 10.10.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

import Foundation
import UIKit

/**
 * Class for Use Case : BabysitterBot
 */
class BabysitterBot: UIViewController {
    
    // Coordinates for Station, Door Point 1, Door Point 2
    let STATION_POINT: (Float, Float) = (0, 0)
    let POINT_1: (Float, Float) = (0, 0)
    let POINT_2: (Float, Float) = (0, 100)
    
    var bc: BotController?;
    var bn: BotNavigator?;
    let bcm = BotConnectionManager.sharedInstance();
    let logger = StreamableLogger();
    
    // Timer
    var timerScanFront: NSTimer = NSTimer()
    var timerScanRight: NSTimer = NSTimer()
    var timerDrive: NSTimer = NSTimer()
    var timerX: NSTimer = NSTimer()
    
    // Control attributes
    var stopped: Bool = false
    var someoneAtDoor: Bool = false
    var log: Bool = true
    var timerDriveRight: NSTimer = NSTimer()
    var velocity: Float = 10
    
    
    @IBAction func startWatch(sender: AnyObject) {
        self.startWatchAction()
    }
    
    @IBAction func start(sender: AnyObject) {
        self.startAction()
    }
    
    @IBAction func stop(sender: AnyObject) {
        self.stopAction()
    }
    
    /**
     * When view did load:
     * - Create connection
     **/
    override func viewDidLoad() {
        super.viewDidLoad();
        
        createConnection()
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
     * Sends the roboter from door point one to door point 2 
     * door point 1 <-----> door point 2
     * During the patrol, the roboter scans if an intruder was detected
     */
    func patrol(back: Bool){
        
        var coordinate = self.POINT_2
        var angle:UInt8 = 0
        
        if(back){
            self.logger.log(.Info, data: "Babybot: Move Back");
            coordinate = self.POINT_1
            angle = 180
            
        } else {
            self.logger.log(.Info, data: "Babybot: Move Forth");
        }
        
        self.moveToWithScan(CGPointMake(CGFloat(coordinate.0), CGFloat(coordinate.1)), scanAngle: angle, completion: { data in
            self.logger.log(.Info, data: "Babybot: Point reached.");
            
            // unless stop was called, go to next streetpoint
            if(!self.stopped){
                self.patrol(!back)
            }
        })
        
    }

    /**
     * Function is called, if User Phone walked by Beacons
     * - Create Connection
     * - Start Action (Patroling)
     **/
    func beaconStartAction(){
        createConnection()
        startAction()
    }
    
    /**
     * Reset Function
     * - Reset Bot Position
     **/
    func reset(){
        self.bc?.resetPosition({ () -> Void in
            self.logger.log(.Info, data: "Reset Bot Position");
        });
    }
    
    /**
     * Is called after click on Start-Button
     * If Bot is not moving
     * - Reset Bot Position
     * - Start Patroling
     */
    func startAction() {
        if(self.stopped == true){
            self.stopped = false
            reset()
            goToDoor()
        }else{
            Toaster.show("Not finished")
        }
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
    * Move Function, specific for BabysitterBot
    * Bot is moving to given Point
    * During moving, Bot is scanning for detecing an intruder
    **/
    func moveToWithScan(point: CGPoint, scanAngle: UInt8, completion: ((ForwardKinematicsData) -> ())? ) {
        self.bc?.stopRangeScan({
            self.bc?.stopMovingWithPositionalUpdate({
                self.logger.log(.Info, data: "\(point)");
                
                self.bc?.startUpdatingPosition(true, completion: { data in
                    self.logger.log(.Info, data: "current position: \(data)");
                    
                    // If Bot reached Point call destReached-Function
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
                        
                        // Bot turns with calculated angle / degrees, to reach point
                        self.bn?.turnToAngle(degrees, speed: (self.bn?.speed)!, completion: { data in
                            let startingPoint = CGPointMake(CGFloat(data.x), CGFloat(data.y));
                            var previousDistance = BotUtils.distance(from: startingPoint, to: point);
                            let dest = CGRectMake(point.x, point.y, 0, 0);
                            let destWithInset = CGRectInset(dest, -1.0, -1.0);
                            
                            self.logger.log(.Info, data: "computed destination area: \(destWithInset), from point: \(point)");
                            
                            self.bc?.startMovingWithPositionalUpdate((self.bn?.speed)!, omega: 0, callback: { data in
                                
                                // Calculation of destination rectangle
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
                            
                            // Flag that prevents saving buggy distance values
                            // Distance needs to be over a threshold more than 5 times to be counted
                            var scanBugFlag = 0.0
                            
                            self.bc?.scanRange(scanAngle, max: scanAngle, inc: 0, callback: { scandata in
                                self.logger.log(.Info, data: "DISTANCE: \(scandata.pingDistance)");
                                self.logger.log(.Info, data: "BUGFLAG: \(scanBugFlag)");
                                
                                if(scandata.pingDistance > 0 && scandata.pingDistance < 35) {

                                    if(scanBugFlag >= 5.0){
                                        self.logger.log(.Info, data: "BabysitterBot: intruder detected");
                                        self.someoneAtDoor = true
                                        
                                        self.bc?.stopRangeScan({
                                            self.bc?.stoptUpdatingPosition();
                                            self.bc?.stop({
                                                //self.goToStation();
                                            });
                                        });
                                        
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
    
    /**
      * Bot reached destination
     **/
    func destinationReached(completion: ((ForwardKinematicsData) -> ())?) {
        self.bc?.stopMovingWithPositionalUpdate({
            self.bc?.startUpdatingPosition(true, completion: { data in
                self.logger.log(.Info, data: "destination reached: \(CGPointMake(CGFloat(data.x), CGFloat(data.y)))");
                completion?(data);
            });
        });
        
        self.bc?.stopRangeScan({});
    }
    
    /**
     * Bot is sent to station
     * Function is called when an intruder is detected
     **/
    func goToStation(){
        
        self.bn?.setTurnSpeed(20)
        self.bn?.setSpeed(20)
        self.bn?.moveToWithoutObstacle(CGPointMake(CGFloat(STATION_POINT.0), CGFloat(STATION_POINT.1)), completion: { data in
            self.logger.log(.Info, data: "baby: MOVE TO Station finished");
            
            self.sendAlarm("Robo at Station");
        })
    }
    
    /**
     * Bot is sent to door and starts patroling
     **/
    func goToDoor(){
        self.logger.log(.Info, data: "goToDoor");
        self.patrol(false)
    }
    
    /**
     * Shows Toaster Message
     **/
    func sendAlarm(message: String){
        Toaster.show(message);
    }
    
    /**** SECOND USE CASE - WITHOUT PATROL - ONLY SCANNING 
     - First Bot is driving to door, turns left, and starts scanning for intruder
     - After detecing an intruder, Bot is turning right and drives home
     *****/
    
     /**
     * Is called after click on Start-Button
     * If Bot is not moving
     * - Reset Bot Position
     * - Start Scanning
     */
    func startWatchAction(){
        if(self.stopped == true){
            self.stopped = false
            logger.log(.Info, data: "Start Action Watchdog");
            
            reset()
            driveAndDetect()
            
        }else{
            Toaster.show("Not finished")
        }
    }
    
    /**
     * Starts Driving
     * Start Scanning and calls checkFrontToDoor each second
     *
     */
    func driveAndDetect(){

        if(self.stopped == true){
            drive()
            self.timerScanFront = NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector: Selector("checkFrontToDoor"),userInfo: nil, repeats: true)
        }
    }
    
    /**
     * Drive Function
     * Starts Bot moving
     */
    func drive(){
        self.logger.log(.Info, data: "drive()");
        bc?.move(self.velocity, omega: 0, completion: nil);
    }
    
    /**
     * Starts Scanning
     * Checks if bot arrived door
     * - then stop moving, timer and scanning. And turn left.
     * - after 8 seconds (time for turning) bot starts scanning for intruder
     **/
    func checkFrontToDoor(){
        self.logger.log(.Info, data: "checkFrontToDoor()");
        self.bc?.scanRange(85, max: 95, inc: 5, callback: { data in
            
            if(data.pingDistance <= 20 && data.pingDistance > 5){
                self.stop()
                self.stopTimerScan()
                self.stopRangeScan()
                self.turnLeft()
                self.timerDriveRight = NSTimer.scheduledTimerWithTimeInterval(8.0, target: self, selector: "checkFrontForEvent", userInfo: nil, repeats: false)
            }
        });
    }
    
    /** 
     * Turn Right
     **/
    func turnRight( ){
        if let bn = bn {
            bn.turnToAngle(Float(-180), speed: Float(15), completion: { [weak self] data in
                self!.bc?.resetPosition({[weak self] data in  });
            });
        }
    }
    
    /**
     * Turn Left
     **/
    func turnLeft( ){
        if let bn = bn {
            bn.turnToAngle(Float(90), speed: Float(15), completion: { [weak self] data in
                self!.bc?.resetPosition({[weak self] data in  });
            });
        }
    }
    
    /**
     * Stops Scanning
     **/
    func stopRangeScan(){
        self.bc?.stopRangeScan({ [weak self] in
            self?.logger.log(.Info, data: "scan stopped")
        });
    }
    
    /**
     * Check for intruder
     * if Intruder is detected:
     * - stop timer, scanning
     * - and drive to station
     **/
    func checkFrontForEvent(){
        self.logger.log(.Info, data: "checkFrontForEvent()");
        self.bc?.scanRange(85, max: 95, inc: 5, callback: { data in
            
            if(data.pingDistance <= 50 && data.pingDistance > 5){
                self.stopTimerScan()
                self.stopRangeScan()
                self.driveHome()
            }
        });
    }
    
    /**
     * Drive to Station
     **/
    func driveHome(){
        if(self.stopped == true){
            turnLeft()
            timerDriveRight = NSTimer.scheduledTimerWithTimeInterval(8.0, target: self, selector: "drive", userInfo: nil, repeats: false)
            self.timerScanFront = NSTimer.scheduledTimerWithTimeInterval(9.0, target:self, selector: Selector("checkFrontToHome"),userInfo: nil, repeats: true)
        }
    }
    
    /**
     * Checks if Bot arrived Station
     **/
    func checkFrontToHome(){
        self.logger.log(.Info, data: "checkFrontToHome()");
        self.bc?.scanRange(85, max: 95, inc: 5, callback: { data in
            if(data.pingDistance <= 20 && data.pingDistance > 5){
                self.stop()
                self.stopTimerScan()
                self.stopRangeScan()
                self.turnRight()
            }
        });
    }
    
    /**
     * Stop Timer Function
     **/
    func stopTimerScan(){
        self.timerScanFront.invalidate()
        self.timerDriveRight.invalidate()
    }
    
    /**
     * Stop moving Bot
     **/
    func stop() {
        self.logger.log(.Info, data: "stop");
        bc?.move(0, omega: 0, completion: nil);
        
    }
}
