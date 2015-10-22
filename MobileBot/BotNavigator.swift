//
//  BotNavigator.swift
//  iRobot
//
//  Created by leemon20 on 14.06.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

import Foundation

class BotNavigator {
    
    var bc: BotController;
    let logger = StreamableLogger();
    
    var bigBot = true;
    // 30 für den kleinen bot
    var slowSpeedDistance: Float = 40;
    // 15 für den kleinen bot
    var stopDistance: Float = 25;
    // 1 für den kleinen bot
    var waitMultiplier: Float = 2;
    
    var speed: Float = 15;
    var turnSpeed: Float = 20;
    var offset: Float = 2.5;
    
    var countAvoids: Float = 0;
    let maxAvoids: Float = 3;
    
    func getSpeed() -> Float{
        return self.speed;
    }
    func setSpeed(speed: Float){
        self.speed = speed;
    }
    func getTurnSpeed() -> Float{
        return self.turnSpeed;
    }
    func setTurnSpeed(turnSpeed: Float){
        self.turnSpeed = turnSpeed;
    }
    func getOffset() -> Float{
        return self.offset;
    }
    func setOffset(offset: Float){
        self.offset = offset;
    }
    
    init(controller: BotController) {
        bc = controller;
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "botTypeDidChange:", name: "BotTypeDidChange", object: nil);
    }
    
    @objc func botTypeDidChange(notification: NSNotification) {
        logger.log(.Info, data: "bot type changed: \(notification.userInfo)");
        
        if let userInfo = notification.userInfo as? [String:Bool] {
            if let usingLargeBot = userInfo["usingLargeBot"] {
                if usingLargeBot {
                    logger.log(.Info, data: "usingLargeBot: \(usingLargeBot)");
                    
                    bigBot = true;
                    slowSpeedDistance = 40;
                    stopDistance = 25;
                    waitMultiplier = 2;
                    
                } else {
                    bigBot = false;
                    slowSpeedDistance = 30;
                    stopDistance = 15;
                    waitMultiplier = 1;
                }
                
                logger.log(.Info, data: "bigBot: \(bigBot), slowSpeedDistance: \(slowSpeedDistance), stopDistance: \(stopDistance), waitMultiplier: \(waitMultiplier)");
            } else {
                logger.log(.Info, data: "usingLargeBot property not found");
            }
        } else {
            logger.log(.Info, data: "not userInfo was provided");
        }
    }
    
    func moveTo(point: CGPoint, completion: ((ForwardKinematicsData) -> ())? ) {
        self.bc.stopMovingWithPositionalUpdate({});
        
        logger.log(.Info, data: "\(point)");
        
        countAvoids = 0;
        var fullSpeed = true;
        
        bc.startUpdatingPosition(once: true, completion: { data in
            self.logger.log(.Info, data: "current position: \(data)");
            
            let angle = atan2f(Float(point.y) - data.y, Float(point.x) - data.x);
            let degrees = angle * 180 / 3.14;
            
            var omegaTmp: Float = 0.0;
            var angle360: Float = degrees + 180;
            var dataPhi360: Float = data.phi + 180;
            
            if(dataPhi360 <= 180){
                if(angle360 > dataPhi360 && angle360 <= (dataPhi360+180)){
                    omegaTmp = self.turnSpeed;
                }else{
                    omegaTmp = -self.turnSpeed;
                }
            }else{
                if(angle360 < dataPhi360 && angle360 >= (dataPhi360-180)){
                    omegaTmp = -self.turnSpeed;
                }else{
                    omegaTmp = self.turnSpeed;
                }
            }
            
            self.bc.startMovingWithPositionalUpdate(0, omega: omegaTmp, callback: { data in
                self.logger.log(.Info, data: "omega observer: \(data) :: \(degrees)");
                
                if ((degrees+self.offset) >= data.phi) && (data.phi >= (degrees-self.offset)) {
                    
                    self.bc.stopMovingWithPositionalUpdate({
                        self.logger.log(.Info, data: "angle reached: \(data.phi)");
                        
                        var xTmp: CGFloat = point.x;
                        var yTmp: CGFloat = point.y;
                        if(point.x >= 0){
                            xTmp -= 5.0;
                        }else{
                            xTmp += 5;
                        }
                        if(point.y >= 0){
                            yTmp -= 5.0;
                        }else{
                            yTmp += 5.0;
                        }
                        
                        let dest = CGRectMake(CGFloat(xTmp), CGFloat(yTmp), 10, 10);
                        
                        self.bc.startMovingWithPositionalUpdate(self.speed, omega: 0, callback: { data in
                            let angle = atan2f(Float(point.y) - data.y, Float(point.x) - data.x);
                            let degrees = angle * 180 / 3.14;
                            self.logger.log(.Info, data: "moving forward: \(data) :: \(point) :: angleToPoint: \(degrees)");
                            
                            var destReached = CGRectContainsPoint(dest, CGPointMake(CGFloat(data.x), CGFloat(data.y)))
                            
                            if destReached {
                                self.logger.log(.Info, data: "destination reached?: \(data) :: \(destReached)");
                                
                                self.bc.stopMovingWithPositionalUpdate({
                                    self.logger.log(.Info, data: "destination reached: \(point)");
                                    
                                    completion?(data);
                                });
                                self.bc.stopRangeScan({});
                            }
                        });
                        
                        self.bc.scanRange(80, max: 100, inc: 3, callback: { scandata in
                            if(fullSpeed && scandata.pingDistance > self.stopDistance && scandata.pingDistance < self.slowSpeedDistance){
                                fullSpeed = false;
                                self.bc.startMovingWithPositionalUpdate(10, omega: 0, callback: { data in
                                    self.logger.log(.Info, data: "something in range, slowing down: \(scandata.pingDistance)");
                                })
                            }
                            if (scandata.pingDistance > 0.0 && scandata.pingDistance < self.stopDistance) {
                                //self.logger.log(.Info, data: "something in range: \(scandata.pingDistance)");
                                self.bc.stopRangeScan({
                                    self.bc.stopMovingWithPositionalUpdate({
                                        self.logger.log(.Info, data: "stopped cause something's in range");
                                        self.avoidObstacle(point, scanData: scandata, positionData: data);
                                    });
                                });
                            }
                        });
                    });
                }
            });
        });
    }
    
    func avoidObstacle(destinationPoint: CGPoint, scanData: PingSensorData, positionData: ForwardKinematicsData) {
        logger.log(.Info, data: "going to avoid obstacle...");
        
        if(countAvoids < maxAvoids){
            countAvoids++;
            self.scanLeftRight({ left, right in
                if(right){
                    self.avoidRight(destinationPoint, scanData: scanData, positionData: positionData);
                }else if(left){
                    self.avoidLeft(destinationPoint, scanData: scanData, positionData: positionData);
                }else{
                    self.bc.stopRangeScan({
                        self.bc.stopMovingWithPositionalUpdate({
                            self.avoidTrap(destinationPoint, scanData: scanData, positionData: positionData)
                        });
                    });
                }
            });
        }else{
            moveTo(destinationPoint, completion: nil)
        }
    }
    
    func avoidTrap(destinationPoint: CGPoint, scanData: PingSensorData, positionData: ForwardKinematicsData){
        var wait = 10;
        self.bc.startMovingWithPositionalUpdate(-10, omega: 0, callback: { data in
            wait--;
            if(wait == 0){
                self.bc.stopMovingWithPositionalUpdate({
                    self.avoidObstacle(destinationPoint, scanData: scanData, positionData: data);
                });
            }
        });
    }
    
    func turnToAngle(angle: Float, speed: Float, completion: (ForwardKinematicsData) -> Void) {
        bc.startMovingWithPositionalUpdate(0.0, omega: speed, callback: { data in
            self.logger.log(.Info, data: "turning: \(data.phi) (\(angle))");
            
            if ((angle+self.offset) >= data.phi) && (data.phi >= (angle-self.offset)) {
                self.bc.stopMovingWithPositionalUpdate({
                    self.logger.log(.Info, data: "angle reached: \(data.phi), desired: \(angle)");
                    
                    completion(data);
                });
            }
        });
    }
    
    func avoidRight(destinationPoint: CGPoint, scanData: PingSensorData, positionData: ForwardKinematicsData){
        logger.log(.Info, data: "going to avoid to the right...");
        
        var date = NSDate();
        var degrees: Float = 0;
        
        if positionData.phi < -90 {
            degrees = ((positionData.phi - 90) % 180) + 180;
        } else {
            degrees = positionData.phi - 90;
        }
        
        // turn right to avoid obstacle
        turnToAngle(degrees, speed: -self.turnSpeed, completion: { data in
            self.bc.startMovingWithPositionalUpdate(self.speed, omega: 0, callback: { data in
                self.logger.log(.Info, data: "moving forward");
            });
            
            var frontDone = false;
            
            self.bc.scanRange(0, max: 100, inc: 3, callback: { scandata in
                self.logger.log(.Info, data: "scan range (0-100): \(scandata)");
                
                // obstacle surpassed
                if ((scandata.pingDistance == 0.0) && (scandata.servoAngle < 30)) || frontDone {
                    self.logger.log(.Info, data: "wait: \(wait)");
                    
                    frontDone = true;
                    
                    self.logger.log(.Info, data: "comparing dates: \(date.timeIntervalSinceNow)");
                    
                    if (abs(Double(date.timeIntervalSinceNow))) > Double(((self.speed/5)*self.waitMultiplier)) {
                        self.logger.log(.Info, data: "left free");
                        
                        date = NSDate();
                        
                        self.bc.stopRangeScan({
                            self.bc.stopMovingWithPositionalUpdate({
                                self.bc.startUpdatingPosition(once: true, completion: { data in
                                
                                    if data.phi > 90 {
                                        degrees = ((data.phi + 90) % 180) - 180;
                                    } else {
                                        degrees = data.phi + 90;
                                    }
                                    
                                    self.turnToAngle(degrees, speed: self.speed, completion: { data in
                                        self.bc.startMovingWithPositionalUpdate(self.speed, omega: 0, callback: { data in
                                            self.logger.log(.Info, data: "moving forward");
                                        });
                                        
                                        var sideDone = false;
                                        
                                        self.bc.scanRange(0, max: 100, inc: 3, callback: { scandata in
                                            self.logger.log(.Info, data: "scanSide: \(scandata)");
                                            
                                            
                                            if ((scandata.pingDistance > 30 || scandata.pingDistance == 0.0) && scandata.servoAngle < 25) || sideDone {
                                                self.logger.log(.Info, data: "wait: \(wait)");
                                                
                                                sideDone = true;
                                                
                                                if (abs(Double(date.timeIntervalSinceNow))) > Double(((self.speed/5)*self.waitMultiplier)) {
                                                    self.logger.log(.Info, data: "left free");
                                                    
                                                    self.bc.stopRangeScan({
                                                        self.bc.stopMovingWithPositionalUpdate({
                                                            self.moveTo(destinationPoint, completion: nil);
                                                        });
                                                    });
                                                }
                                                
                                            } else if (scandata.pingDistance < 15) && (scandata.pingDistance > 0) {
                                                self.bc.stopRangeScan({
                                                    self.logger.log(.Info, data: "scanSide: somethings in range: \(scandata)");

                                                    self.bc.stopMovingWithPositionalUpdate({
                                                        self.bc.startUpdatingPosition(once: true, completion: { data in
                                                            self.avoidObstacle(destinationPoint, scanData: scanData, positionData: data);
                                                        });
                                                    });
                                                });
                                            }
                                        });
                                    });
                                });
                            });
                        });
                    }

                }
            });
        });
    }
    
    func avoidLeft(destinationPoint: CGPoint, scanData: PingSensorData, positionData: ForwardKinematicsData){
        logger.log(.Info, data: "going to avoid to the left...");
        
        var wait = 100/self.speed * self.waitMultiplier;
        var degrees: Float = 0;
        
        if(positionData.phi > 90){
            degrees = ((positionData.phi + 90) % 180) - 180;
        }else{
            degrees = positionData.phi + 90;
        }
        
        self.bc.startMovingWithPositionalUpdate(0.0, omega: self.turnSpeed, callback: { data in
            self.logger.log(.Info, data: "turning left: \(data.phi) (\(degrees))");
            if ((degrees+self.offset) >= data.phi) && (data.phi >= (degrees-self.offset)) {
                self.bc.stopMovingWithPositionalUpdate({
                    self.logger.log(.Info, data: "angle reached: \(data.phi)");
                    
                    var positionDataTmp: ForwardKinematicsData = (x: 0, y: 0, phi: 0);
                    self.bc.startMovingWithPositionalUpdate(self.speed, omega: 0, callback: { data in
                        self.logger.log(.Info, data: "moving forward");
                        positionDataTmp = data;
                    });
                    
                    var frontDone: Bool = false;
                    self.bc.scanRange(80, max: 180, inc: 3, callback: { scandata in
                        self.logger.log(.Info, data: "scanFront: \(scandata)");
                        if(frontDone){wait -= 1;}
                        if (scandata.pingDistance == 0.0 && scandata.servoAngle > 155) {
                            self.logger.log(.Info, data: "wait: \(wait)");
                            frontDone = true;
                            if(wait <= 0){
                                self.logger.log(.Info, data: "right free");
                                wait = 100/self.speed * self.waitMultiplier;
                                self.bc.stopRangeScan({
                                    self.bc.stopMovingWithPositionalUpdate({
                                        
                                        if(data.phi < -90){
                                            degrees = ((data.phi - 90) % 180) + 180;
                                        }else{
                                            degrees = data.phi - 90;
                                        }
                                        
                                        self.bc.startMovingWithPositionalUpdate(0, omega: -self.turnSpeed, callback: { data in
                                            self.logger.log(.Info, data: "turning right: \(data.phi) (\(degrees))");
                                            if ((degrees+self.offset) >= data.phi) && (data.phi >= (degrees-self.offset)) {
                                                self.bc.stopMovingWithPositionalUpdate({
                                                    self.logger.log(.Info, data: "angle reached: \(data.phi)");
                                                    
                                                    var positionDataTmp: ForwardKinematicsData = (x: 0, y: 0, phi: 0);
                                                    self.bc.startMovingWithPositionalUpdate(self.speed, omega: 0, callback: { data in
                                                        self.logger.log(.Info, data: "moving forward");
                                                        positionDataTmp = data;
                                                    });
                                                    
                                                    var sideDone = false;
                                                    self.bc.scanRange(80, max: 180, inc: 3, callback: { scandata in
                                                        self.logger.log(.Info, data: "scanSide: \(scandata)");
                                                        if(sideDone){wait -= 1;}
                                                        if ((scandata.pingDistance>30 || scandata.pingDistance==0.0) && scandata.servoAngle > 155) {
                                                            self.logger.log(.Info, data: "wait: \(wait)");
                                                            sideDone = true;
                                                            if(wait <= 0) {
                                                                self.logger.log(.Info, data: "right free");
                                                                self.bc.stopRangeScan({
                                                                    self.bc.stopMovingWithPositionalUpdate({
                                                                        self.moveTo(destinationPoint, completion: nil);
                                                                    });
                                                                });
                                                            }
                                                        }else if (scandata.pingDistance < 15 && scandata.pingDistance != 0) {
                                                            self.bc.stopRangeScan({
                                                                self.logger.log(.Info, data: "scanSide: somethings in range: \(scandata)");
//                                                                self.avoidLeft(destinationPoint, scanData: scanData, positionData: positionDataTmp);
                                                                self.bc.stopMovingWithPositionalUpdate({
                                                                    self.avoidObstacle(destinationPoint, scanData: scanData, positionData: positionDataTmp);
                                                                });
                                                            });
                                                        }
                                                    });
                                                });
                                            }
                                        });
                                    });
                                });
                            }
                        }else if (scandata.pingDistance < 10 && scandata.pingDistance != 0) {
                            self.bc.stopRangeScan({
                                self.logger.log(.Info, data: "scanFront: somethings in range: \(scandata)");
//                                self.avoidRight(destinationPoint, scanData: scanData, positionData: positionDataTmp);
                                self.bc.stopMovingWithPositionalUpdate({
                                    self.avoidObstacle(destinationPoint, scanData: scanData, positionData: positionDataTmp);
                                });
                            });
                        }
                    });
                });
            }
        });
    }

    
    func scanLeftRight(completion: (left: Bool, right: Bool) -> ()) {
        logger.log(.Info, data: "check in which direction to avoid...");
        var leftDone = false;
        var rightDone = false;
        var leftFree = false;
        var rightFree = false;
//        self.bc.scanRange(0, max: 0, inc: 0, callback: { scandata in
//            self.logger.log(.Info, data: "scanLeft: \(scandata)");
//            if (scandata.servoAngle < 20) {
//                if(scandata.pingDistance == 0.0){
//                    leftFree = true;
//                }
//                self.bc.scanRange(180, max: 180, inc: 0, callback: { scandata in
//                    self.logger.log(.Info, data: "scanRight: \(scandata)");
//                    if (scandata.servoAngle > 160) {
//                        if(scandata.pingDistance == 0.0){
//                            rightFree = true;
//                        }
//                        self.bc.stopRangeScan({
//                            self.logger.log(.Info, data: "leftFree: \(leftFree), rightFree: \(rightFree)");
//                            completion(left: leftFree, right: rightFree);
//                        });
//                    }
//                });
//            }
//        });
        self.bc.scanRange(0, max: 180, inc: 3, callback: { scandata in
            self.logger.log(.Info, data: "scanLeftRight: \(scandata)");
            if(scandata.servoAngle < 90){
                if(scandata.pingDistance == 0.0){
                    leftFree = true;
                    leftDone = true;
                }
                if (scandata.servoAngle < 25 ) {
                    leftDone = true;
                }
                
            }else{
                if(scandata.pingDistance == 0.0){
                    rightFree = true;
                    rightDone = true;
                }
                if (scandata.servoAngle > 155) {
                    rightDone = true;
                }
                
            }
            if(leftDone && rightDone){
                self.bc.stopRangeScan({
                    self.logger.log(.Info, data: "leftFree: \(leftFree), rightFree: \(rightFree)");
                    completion(left: leftFree, right: rightFree);
                });
            }
        });
    }
    
    /**
    * Turns the robot in the wright direction to the given angle.
    *
    * !!! DOES NOT WORK!!!
    *
    * :param: angle The angle to turn to
    * :param: turnSpeed The speed in which the robot is rotating
    * :param: callback Funktion to be called everytime a new value is received
    */
    //    func turnToAngle(angle: Float, turnSpeed: Float, offset: Float, callback: ForwardKinematicsData -> Void){
    //
    //        var omegaTmp: Float = 0.0;
    //        var angle360: Float = angle + 180;
    //
    //        self.startUpdatingPosition(once: true, completion: { data in
    //
    //            var dataPhi360: Float = data.phi + 180;
    //
    //            // find out in which direction to turn
    //            if((angle360+offset) >= dataPhi360) && (dataPhi360 >= (angle360-offset)){
    //                callback(data);
    //            }else{
    //                if(dataPhi360 <= 180){
    //                    if(angle360 > dataPhi360 && angle360 <= (dataPhi360+180)){
    //                        omegaTmp = turnSpeed;
    //                    }else{
    //                        omegaTmp = -turnSpeed;
    //                    }
    //                }else{
    //                    if(angle360 < dataPhi360 && angle360 >= (dataPhi360-180)){
    //                        omegaTmp = -turnSpeed;
    //                    }else{
    //                        omegaTmp = turnSpeed;
    //                    }
    //                }
    //
    //                self.startMovingWithPositionalUpdate(0, omega: omegaTmp, callback: { turndata in
    //                    self.movementLogger.debug("turning to angle : \(angle) (\(turndata))");
    //                    var turndataPhi360: Float = turndata.phi + 180;
    //
    //                    if((angle360+offset) >= turndataPhi360) && (turndataPhi360 >= (angle360-offset)){
    //                        self.stopMovingWithPositionalUpdate({
    //                            self.movementLogger.debug("angle reached");
    //                            callback(turndata);
    //                        });
    //                    }
    //
    //                    // if rotated over the angle but did not recognized, turn the other way around again
    //                    if(omegaTmp < 0){
    //                        if(turndataPhi360 < angle360 && turndataPhi360 > (angle360-10)){
    //                            if(turnSpeed < -5){
    //                                self.turnToAngle(angle, turnSpeed: turnSpeed+5, offset: offset, callback: callback);
    //                            }else{
    //                                self.turnToAngle(angle, turnSpeed: -5, offset: offset, callback: callback);
    //                            }
    //                        }
    //                    }else{
    //                        if(turndataPhi360 > angle360 && turndataPhi360 < (angle360+10)){
    //                            if(turnSpeed > 5){
    //                                self.turnToAngle(angle, turnSpeed: turnSpeed-5, offset: offset, callback: callback);
    //                            }else{
    //                                self.turnToAngle(angle, turnSpeed: 5, offset: offset, callback: callback);
    //                            }
    //                        }
    //                    }
    //                });
    //            }
    //        });
    //    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self);
        
        logger.log(.Info, data: "✝ (rip) ✝");
    }
}