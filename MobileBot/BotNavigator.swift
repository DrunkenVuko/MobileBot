//
//  BotNavigator.swift
//  iRobot
//
//  Created by master on 14.06.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

import Foundation
import UIKit

class BotNavigator {
    
    var bc: BotController;
    let logger = StreamableLogger();
    
    // Variablen die Abhängigkeiten zu der Größe des Bots aufweisen
    var bigBot = true;
    var slowSpeedDistance: Float = 30;
    var stopDistance: Float = 15;
    var waitMultiplier: Float = 0.7;
    
    // allgemeine Variablen die die Bewegung des Bots beeinflussen
    var speed: Float = 15;
    var turnSpeed: Float = 20;
    var offset: Float = 2.5;
    
    // Variablen damit nicht unendlich rekursiv ausgewichen wird
    var countAvoids: Float = 0;
    let maxAvoids: Float = 3;
    
    var positiondata: (Float, Float, Float) = (0, 0, 0)
    var parkStart: (Float, Float, Float) = (0, 0, 0)
    var inParkingLot = false
    
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
    
    // die Initialisierungsmethode
    init(controller: BotController) {
        bc = controller;
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "botTypeDidChange:", name: "BotTypeDidChange", object: nil);
    }
    
    /**
    *
    * Funktion um die Variablen zu Ändern die Abhängigkeiten mit der Größe des Bots aufweisen
    **/
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
    
    /**
    * 
    * Diese Funktion lässt den Roboter zu einer Bestimmten Position in seinem Koordinatensystem fahren. 
    * Falls auf dem Weg ein Hindernis auftaucht, wird es umfahren.
    **/
    func moveTo(point: CGPoint, completion: ((ForwardKinematicsData) -> ())? ) {
        self.bc.stopRangeScan({
            self.bc.stopMovingWithPositionalUpdate({
                self.logger.log(.Info, data: "\(point)");
                
                self.countAvoids = 0;
                var fullSpeed = true;
                
                self.bc.startUpdatingPosition(true, completion: { data in
                    self.logger.log(.Info, data: "current position: \(data)");
                    
                    let angle = atan2f(Float(point.y) - data.y, Float(point.x) - data.x);
                    let degrees = angle * 180 / 3.14;
                    
                    // Roboter dreht sich in die richtige Richtung
                    self.turnToAngle(degrees, speed: self.speed, completion: { data in
                        let startingPoint = CGPointMake(CGFloat(data.x), CGFloat(data.y));
//                        var previousDistance = BotUtils.distance(from: startingPoint, to: point);
                        var previousDistance = Float(10000000)

                        let dest = CGRectMake(point.x, point.y, 0, 0);
                        let destWithInset = CGRectInset(dest, -1.0, -1.0);
                        
                        self.logger.log(.Info, data: "computed destination area: \(destWithInset), from point: \(point)");
                        
                        self.bc.startMovingWithPositionalUpdate(self.speed, omega: 0, callback: { data in
                            
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
//                                self.moveTo(point, completion: completion)
                            }
                            
                            previousDistance = currentDistance;
                        });
                        
                        // flag welches verhindern soll dass ein Hindernis vom Roboter wahrgenommen wird, wenn keines vorhanden ist
                        // es muss mehrere male hintereinander vom Roboter gesendet werden, dass sich etwas vor ihm befindet
                        var scanBugFlag = 0.0;
                        
                        self.bc.scanRange(80, max: 100, inc: 3, callback: { scandata in
                            
                            // hier wird der Roboter verlangsamt, wenn er ein Hindernis erkennt, es aber noch weit genug entfernt ist
                            // das soll verhindern, dass der Roboter durch lange Übertragungszeiten, zu spät stoppt und gegen das hindernis fährt
                            if(fullSpeed && scandata.pingDistance > self.stopDistance && scandata.pingDistance < self.slowSpeedDistance){
                                fullSpeed = false;
                                self.bc.startMovingWithPositionalUpdate(10, omega: 0, callback: { data in
                                    self.logger.log(.Info, data: "something in range, slowing down: \(scandata.pingDistance)");
                                })
                            }
                            
                            // wenn sich der Roboter nah genug vor einem Hindernis befindet, stoppt er und es wird der Algorithmus gestartet zum Umfahren des Hindernisses
                            if (scandata.pingDistance > 0.0 && scandata.pingDistance < self.stopDistance) {
                                //self.logger.log(.Info, data: "something in range: \(scandata.pingDistance)");
                                if(scanBugFlag >= 2.0){
                                    self.bc.stopRangeScan({
                                        self.bc.stopMovingWithPositionalUpdate({
                                            self.logger.log(.Info, data: "stopped cause something's in range");
                                            self.avoidObstacle(point, scanData: scandata, positionData: data, completion: completion);
                                        });
                                    });
                                }else{
                                    scanBugFlag++;
                                }
                            }else{
                                scanBugFlag = 0;
                            }
                            
                            //                    Code ohne das Flag und die Geschwindigkeitsreduktion, zum testen
                            //
                            //                    if (scandata.pingDistance > 0.0) && (scandata.pingDistance < self.stopDistance) {
                            //                        self.logger.log(.Info, data: "something in range: \(scandata.pingDistance)");
                            //
                            //                        self.bc.stopRangeScan({
                            //                            self.bc.stopMovingWithPositionalUpdate({
                            //                                self.logger.log(.Info, data: "stopped cause something's in range");
                            //                                self.avoidObstacle(point, scanData: scandata, positionData: data);
                            //                            });
                            //                        });
                            //                    }
                        });
                    });
                });
            });
        })
    }
    
    /**
     *
     * Diese Funktion lässt den Roboter zu einer Bestimmten Position in seinem Koordinatensystem fahren.
     * Hindernisse werden nicht umfahren.
     **/
    func moveToWithoutObstacle(point: CGPoint, completion: ((ForwardKinematicsData) -> ())? ) {
        self.bc.stopRangeScan({
            self.bc.stopMovingWithPositionalUpdate({
                self.logger.log(.Info, data: "\(point)");
                
                self.bc.startUpdatingPosition(true, completion: { data in
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
                        let degrees = angle * (180 / 3.14);
                        
                        // Roboter dreht sich in die richtige Richtung
                        self.turnToAngle(degrees, speed: self.speed, completion: { data in
                            let startingPoint = CGPointMake(CGFloat(data.x), CGFloat(data.y));
                            var previousDistance = BotUtils.distance(from: startingPoint, to: point);
                            let dest = CGRectMake(point.x, point.y, 0, 0);
                            let destWithInset = CGRectInset(dest, -1.0, -1.0);
                            
                            self.logger.log(.Info, data: "computed destination area: \(destWithInset), from point: \(point)");
                            
                            self.bc.startMovingWithPositionalUpdate(self.speed, omega: 0, callback: { data in
                                
                                // Berechnung des Rechtecks um den Zielpunkt
                                let angle = atan2f(Float(point.y) - data.y, Float(point.x) - data.x);
                                let degrees = angle * (180 / 3.14);
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
                                    //                                self.moveTo(point, completion: completion)
                                }
                                
                                previousDistance = currentDistance;
                            });
                            
                        });
                    }
                    
                });
            });
        })
    }
    
    /**
     *
     * Diese Funktion dient dem ParkingBot Use Case
     **/
    func moveToWithScan(point: CGPoint, scanAngle: UInt8, completion: ((ForwardKinematicsData) -> ())? ) {
        self.bc.stopRangeScan({
            self.bc.stopMovingWithPositionalUpdate({
                self.logger.log(.Info, data: "\(point)");
                
                self.bc.startUpdatingPosition(true, completion: { data in
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
                        self.turnToAngle(degrees, speed: self.speed, completion: { data in
                            let startingPoint = CGPointMake(CGFloat(data.x), CGFloat(data.y));
                            var previousDistance = BotUtils.distance(from: startingPoint, to: point);
                            let dest = CGRectMake(point.x, point.y, 0, 0);
                            let destWithInset = CGRectInset(dest, -1.0, -1.0);
                            
                            self.logger.log(.Info, data: "computed destination area: \(destWithInset), from point: \(point)");
                            
                            self.bc.startMovingWithPositionalUpdate(self.speed, omega: 0, callback: { data in
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
                            
                            self.bc.scanRange(scanAngle, max: scanAngle, inc: 0, callback: { scandata in
                                self.logger.log(.Info, data: "DISTANCE: \(scandata.pingDistance)");
                                self.logger.log(.Info, data: "BUGFLAG: \(scanBugFlag)");

                                if(scandata.pingDistance == 0 || scandata.pingDistance > 35) {
                                    if(!self.inParkingLot){
                                        if(scanBugFlag == 2.0){
                                            self.logger.log(.Info, data: "EMPTY PARKING SPACE STARTED AT \(self.positiondata)");
                                            self.inParkingLot = true
                                            self.parkStart = self.positiondata
                                            
                                        }else{
                                            scanBugFlag++
                                        }
                                    } else if(scanBugFlag < 2.0){
                                        scanBugFlag++
                                    }

                                } else {
                                    if(self.inParkingLot){
                                        if(scanBugFlag == 0.0){
                                        self.logger.log(.Info, data: "EMPTY PARKING SPACE ENDED AT \(self.positiondata)");
                                        self.inParkingLot = false
                                        NSNotificationCenter.defaultCenter().postNotificationName("PARKINGLOT_END", object: nil, userInfo:
                                            ["parkingStartX":self.parkStart.0,
                                                "parkingStartY":self.parkStart.1,
                                                "parkingEndX":self.positiondata.0,
                                            "parkingEndY":self.positiondata.1])
                                        }else{
                                            scanBugFlag--;
                                        }
                                    } else if(scanBugFlag > 0.0){
                                        scanBugFlag--
                                    }
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
        self.bc.stopMovingWithPositionalUpdate({
            self.bc.startUpdatingPosition(true, completion: { data in
                self.logger.log(.Info, data: "destination reached: \(CGPointMake(CGFloat(data.x), CGFloat(data.y)))");
                completion?(data);
            });
        });
        
        self.bc.stopRangeScan({});
        
        if(self.inParkingLot){
            self.logger.log(.Info, data: "EMPTY PARKING SPACE ENDED AT \(self.positiondata)");

            NSNotificationCenter.defaultCenter().postNotificationName("PARKINGLOT_END", object: nil, userInfo:
                ["parkingStartX":self.parkStart.0,
                    "parkingStartY":self.parkStart.1,
                    "parkingEndX":self.positiondata.0,
                    "parkingEndY":self.positiondata.1])
        }
    }
    
    // diese Funktion wird ausgeführt um ein Hindernis zu umfahren.
    // es wird links und rechts gescannt, welche Richtung frei zum Umfahren ist. Falls keine wird eine Methode zum ausweichen einer Sackgasse ausgeführt
    func avoidObstacle(destinationPoint: CGPoint, scanData: PingSensorData, positionData: ForwardKinematicsData, completion: ((ForwardKinematicsData) -> ())?) {
        logger.log(.Info, data: "going to avoid obstacle...");
        
        if(countAvoids < maxAvoids){
            countAvoids++;
            self.scanLeftRight({ left, right in
                if(right){
                    self.avoidRight(destinationPoint, scanData: scanData, positionData: positionData, completion: completion);
                }else if(left){
                    self.avoidLeft(destinationPoint, scanData: scanData, positionData: positionData, completion: completion);
                }else{
                    self.bc.stopRangeScan({
                        self.bc.stopMovingWithPositionalUpdate({
                            self.avoidTrap(destinationPoint, scanData: scanData, positionData: positionData, completion: completion)
                        });
                    });
                }
            });
        }else{
            moveTo(destinationPoint, completion: completion)
        }
        
        //avoidLeft(destinationPoint, scanData: scanData, positionData: positionData);
    }
    
    // ist beim Umfahren eines Hindernisses links und rechts keine Richtung frei, fährt der Roboter ein Stück zurück und scannt 
    // erneut welche Richtung frei zum Umfahren ist
    func avoidTrap(destinationPoint: CGPoint, scanData: PingSensorData, positionData: ForwardKinematicsData, completion: ((ForwardKinematicsData) -> ())?){
        var wait = 10;
        self.bc.startMovingWithPositionalUpdate(-10, omega: 0, callback: { data in
            wait--;
            if(wait == 0){
                self.bc.stopMovingWithPositionalUpdate({
                    self.avoidObstacle(destinationPoint, scanData: scanData, positionData: data, completion: completion);
                });
            }
        });
    }
    
    // da der Roboter nur Befehle zum vorwärts, rückwärts und zum drehen kennt, ermittelt diese Methode in welche Richtung sich der Roboter drehen muss
    // und wann er den Zielwinkel erreicht hat
    func turnToAngle(angle: Float, speed: Float, completion: (ForwardKinematicsData) -> Void) {
        var omegaTmp: Float = 0;
    
        self.bc.startUpdatingPosition(true, completion: { data in
            
            // berechnet in welcher Richtung der Zielwinkel schneller erreicht wird
            if((angle+self.offset) >= data.phi) && (data.phi >= (angle-self.offset)){
                completion(data);
            }else{
                if(data.phi <= 0){
                    if(angle > data.phi && angle <= (data.phi+180)){
                        omegaTmp = speed;
                    }else{
                        omegaTmp = -speed;
                    }
                }else{
                    if(angle < data.phi && angle >= (data.phi-180)){
                        omegaTmp = -speed;
                    }else{
                        omegaTmp = speed;
                    }
                }
            
//                self.bc.startMovingWithPositionalUpdate(0.0, omega: omegaTmp, callback: { data in
//                    self.logger.log(.Info, data: "turning: \(data.phi) (\(angle))");
//                    
//                    if ((angle+self.offset) >= data.phi) && (data.phi >= (angle-self.offset)) {
//                        self.bc.stopMovingWithPositionalUpdate({
//                            self.logger.log(.Info, data: "angle reached: \(data.phi), desired: \(angle)");
//                            
//                            completion(data);
//                        });
//                    }
//                });
                
                var previousAngle = data.phi;
                
                self.bc.startMovingWithPositionalUpdate(0, omega: omegaTmp, callback: { turndata in
                    self.logger.log(.Info, data: "turning to angle : \(angle), data: \(turndata), omega: \(omegaTmp)");
                    
                    let currentAngle = turndata.phi;
                    //var turndataPhi360: Float = turndata.phi + 180;
            
                    // hier wird überprüft ob sich der Roboter in dem Bereich um den Zielwinkel befindet
                    if((angle+self.offset) >= turndata.phi) && (turndata.phi >= (angle-self.offset)){
                            self.bc.stopMovingWithPositionalUpdate({
                                self.logger.log(.Info, data: "angle reached");
                                completion(turndata);
                            });
                    }else{
                    
                        self.logger.log(.Info, data: "previous angle: \(previousAngle), current angle: \(currentAngle)");
                    
                        previousAngle = currentAngle;
                    
                        // in der folgenden Verzweigung wird überprüft ob der Roboter sich durch Übertragungsverzögerungen 
                        // über den Zielwinkel gedreht hat. Ist das der Fall, wird rekursiv die turnTo-Methode mit verringertem Speed ausgeführt, was dazu führt,
                        // dass erneut die Drehrichtung berechnet wird und der Roboter sich langsam zurück dreht
                        if(omegaTmp < 0){
                            if(turndata.phi < (angle-10) && turndata.phi > (angle-25)){
                                self.bc.stopMovingWithPositionalUpdate({
//                                  if(speed < -5){
//                                      self.turnToAngle(angle, speed: speed+5, completion: completion);
//                                  }else{
//                                      self.turnToAngle(angle, speed: -5, completion: completion);
//                                  }
                                    self.turnToAngle(angle, speed: 5, completion: completion);
                                });
                            }
                        }else{
                            if(turndata.phi > (angle+10) && turndata.phi < (angle+25)){
                                self.bc.stopMovingWithPositionalUpdate({
//                                  if(speed > 5){
//                                      self.turnToAngle(angle, speed: speed-5, completion: completion);
//                                  }else{
//                                      self.turnToAngle(angle, speed: 5, completion: completion);
//                                  }
                                    self.turnToAngle(angle, speed: -5, completion: completion);
                                });
                            }
                        }
                    }
                });
            }
        });
    }
    
    // diese Methode lässt den Roboter ein Hindernis nach rechts ausweichen.
    // Dabei wird weiterhin gescannt ob sich wieder etwas im Weg befindet und falls ja, wird der Umfahren-Algorithmus rekursiv ausgeführt
    // Der Roboter dreiht sich um 90° nach rechts, fährt die Front des Hindernisses ab uns scannt ob der Weg frei ist.
    // Wenn ja, dreht er sich um 90° nach links und fährt di Seite des Hindernisses ab. ist auch diese abgefahren, fährt er weiter zum eigentlichen Zielpunkt
    func avoidRight(destinationPoint: CGPoint, scanData: PingSensorData, positionData: ForwardKinematicsData, completion: ((ForwardKinematicsData) -> ())?){
        logger.log(.Info, data: "going to avoid to the right...");
        
        var degrees: Float = 0;
        
        // berechnet den Winkel der einer Drehung um 90° nach rechts entspricht
        if positionData.phi < -90 {
            degrees = ((positionData.phi - 90) % 180) + 180;
        } else {
            degrees = positionData.phi - 90;
        }
    
        // dreht den Roboter 90° nach rechts
        turnToAngle(degrees, speed: self.turnSpeed, completion: { data in
            var positionDataTmp: ForwardKinematicsData = (x: 0, y: 0, phi: 0);
            self.bc.startMovingWithPositionalUpdate(self.speed, omega: 0, callback: { data in
                self.logger.log(.Info, data: "moving forward");
                positionDataTmp = data;
            });
            
            var date: NSDate?;
            var frontDone = false;
            
            // scannt links und geradeaus ob sich entweder wieder etwas im Weg befindet oder ob die Front des Hindernisses umfahren wurde
            self.bc.scanRange(0, max: 100, inc: 3, callback: { scandata in
                self.logger.log(.Info, data: "scan range (0-100): \(scandata)");
                
                if date == nil {
                    date = NSDate();
                }
                
                // die Front des Hindernisses wurde umfahren
                if ((scandata.pingDistance == 0.0) && (scandata.servoAngle < 30)) || frontDone {
                    
                    frontDone = true;
                    
                    let timeSineNow = abs(Double(date!.timeIntervalSinceNow));
                    let timeToWait = Double(((50/self.speed)*self.waitMultiplier));
                    let enoughTimePassed = timeSineNow > timeToWait;
                    
                    self.logger.log(.Info, data: "time since now: \(timeSineNow), time to wait: \(timeToWait), enough time passed: \(enoughTimePassed)");
                    
                    // nachdem die Front umfahren wurde, fährt der Roboter, abhängig von seiner Größe ein Stück weiter 
                    // um ganz an der Front des Hindernisses vorbei zu fahren
                    if enoughTimePassed {
                        self.logger.log(.Info, data: "left free");
                        
                        date = nil;
                        
                        self.bc.stopRangeScan({
                            self.bc.stopMovingWithPositionalUpdate({
                                self.bc.startUpdatingPosition(true, completion: { data in
                                
                                    // berechnet den Winkel der einer Drehung um 90° nach links entspricht
                                    if data.phi > 90 {
                                        degrees = ((data.phi + 90) % 180) - 180;
                                    } else {
                                        degrees = data.phi + 90;
                                    }
                                    
                                    // dreht den Roboter 90° nach link
                                    self.turnToAngle(degrees, speed: self.speed, completion: { data in
                                        self.bc.startMovingWithPositionalUpdate(self.speed, omega: 0, callback: { data in
                                            self.logger.log(.Info, data: "moving forward");
                                        });
                                        
                                        var sideDone = false;
                                        
                                        self.bc.scanRange(0, max: 100, inc: 3, callback: { scandata in
                                            self.logger.log(.Info, data: "scanSide: \(scandata)");
                                            
                                            if date == nil {
                                                date = NSDate();
                                            }
                                            
                                            // die Seite des Hindernisses ist umfahren
                                            if ((scandata.pingDistance > 30 || scandata.pingDistance == 0.0) && scandata.servoAngle < 25) || sideDone {
//                                                self.logger.log(.Info, data: "wait: \(wait)");
                                                
                                                sideDone = true;
                                                let timeSineNow = abs(Double(date!.timeIntervalSinceNow));
                                                let timeToWait = Double(((50/self.speed)*self.waitMultiplier));
                                                let enoughTimePassed = timeSineNow > timeToWait;
                                                
                                                self.logger.log(.Info, data: "time since now: \(timeSineNow), time to wait: \(timeToWait), enough time passed: \(enoughTimePassed)");
                                                
                                                // der Roboter fährt wieder ein Stück weiter damit gewährleitste ist, dass das Hindernis auch wirklich umfahren ist
                                                if enoughTimePassed {
                                                    self.logger.log(.Info, data: "left free");
                                                    
                                                    // das Hindernis wurde erfolgreich umfahren und es wird weiter zum eigentlichen Zielpunkt gefahren
                                                    self.bc.stopRangeScan({
                                                        self.bc.stopMovingWithPositionalUpdate({
                                                            self.moveTo(destinationPoint, completion: completion);
                                                        });
                                                    });
                                                }
                                                
                                            // befindet sich erneut ein Hindernis im Weg des Roboters wird nochmals die Umfahren-Methode ausgeführt
                                            } else if (scandata.pingDistance < 15) && (scandata.pingDistance > 0) {
                                                self.bc.stopRangeScan({
                                                    self.logger.log(.Info, data: "scanSide: somethings in range: \(scandata)");

                                                    self.bc.stopMovingWithPositionalUpdate({
                                                        self.bc.startUpdatingPosition(true, completion: { data in
                                                            self.avoidObstacle(destinationPoint, scanData: scanData, positionData: data, completion: completion);
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
                
                // befindet sich erneut ein Hindernis im Weg des Roboters wird nochmals die Umfahren-Methode ausgeführt
                }else if (scandata.pingDistance < 10 && scandata.pingDistance != 0) {
                    self.bc.stopRangeScan({
                        self.logger.log(.Info, data: "scanFront: somethings in range: \(scandata)");
                        //                                self.avoidRight(destinationPoint, scanData: scanData, positionData: positionDataTmp);
                        self.bc.stopMovingWithPositionalUpdate({
                            self.avoidObstacle(destinationPoint, scanData: scanData, positionData: positionDataTmp, completion: completion);
                        });
                    });
                }
            });
        });
    }
    
    // analog zur vorherigen Methode avoidRight, nur links am Hindernis entlang
    // Hinweis: diese Methode ist redundant. Man könnte das Ausweichen in beide Richtungen in eine Methode Packen
    func avoidLeft(destinationPoint: CGPoint, scanData: PingSensorData, positionData: ForwardKinematicsData, completion: ((ForwardKinematicsData) -> ())?){
        logger.log(.Info, data: "going to avoid to the left...");
        
        var degrees: Float = 0;
        
        if(positionData.phi > 90){
            degrees = ((positionData.phi + 90) % 180) - 180;
        }else{
            degrees = positionData.phi + 90;
        }
        
        // turn right to avoid obstacle
        turnToAngle(degrees, speed: self.turnSpeed, completion: { data in
            var positionDataTmp: ForwardKinematicsData = (x: 0, y: 0, phi: 0);
            self.bc.startMovingWithPositionalUpdate(self.speed, omega: 0, callback: { data in
                self.logger.log(.Info, data: "moving forward");
                positionDataTmp = data;
            });
            
            var date: NSDate?;
            var frontDone = false;
            
            self.bc.scanRange(80, max: 180, inc: 3, callback: { scandata in
                self.logger.log(.Info, data: "scan range (80-180): \(scandata)");
                
                if date == nil {
                    date = NSDate();
                }
                
                // obstacle surpassed
                if ((scandata.pingDistance == 0.0) && (scandata.servoAngle < 155)) || frontDone {
//                    self.logger.log(.Info, data: "wait: \(wait)");
                    
                    frontDone = true;
                    
                    let timeSineNow = abs(Double(date!.timeIntervalSinceNow));
                    let timeToWait = Double(((50/self.speed)*self.waitMultiplier));
                    let enoughTimePassed = timeSineNow > timeToWait;
                    
                    self.logger.log(.Info, data: "time since now: \(timeSineNow), time to wait: \(timeToWait), enough time passed: \(enoughTimePassed)");
                    
                    if (enoughTimePassed) {
                        self.logger.log(.Info, data: "right free");
                        
                        date = nil;
                        
                        self.bc.stopRangeScan({
                            self.bc.stopMovingWithPositionalUpdate({
                                self.bc.startUpdatingPosition(true, completion: { data in
                                    
                                    if(data.phi < -90){
                                        degrees = ((data.phi - 90) % 180) + 180;
                                    }else{
                                        degrees = data.phi - 90;
                                    }
                                    
                                    self.turnToAngle(degrees, speed: self.speed, completion: { data in
                                        self.bc.startMovingWithPositionalUpdate(self.speed, omega: 0, callback: { data in
                                            self.logger.log(.Info, data: "moving forward");
                                        });
                                        
                                        var sideDone = false;
                                        
                                        self.bc.scanRange(80, max: 180, inc: 3, callback: { scandata in
                                            self.logger.log(.Info, data: "scanSide: \(scandata)");
                                            
                                            if date == nil {
                                                date = NSDate();
                                            }
                                            
                                            if ((scandata.pingDistance > 30 || scandata.pingDistance == 0.0) && scandata.servoAngle < 155) || sideDone {
//                                                self.logger.log(.Info, data: "wait: \(wait)");
                                                
                                                sideDone = true;
                                                let timeSineNow = abs(Double(date!.timeIntervalSinceNow));
                                                let timeToWait = Double(((50/self.speed)*self.waitMultiplier));
                                                let enoughTimePassed = timeSineNow > timeToWait;
                                                
                                                self.logger.log(.Info, data: "time since now: \(timeSineNow), time to wait: \(timeToWait), enough time passed: \(enoughTimePassed)");
                                                
                                                if (enoughTimePassed) {
                                                    self.logger.log(.Info, data: "left free");
                                                    
                                                    self.bc.stopRangeScan({
                                                        self.bc.stopMovingWithPositionalUpdate({
                                                            self.moveTo(destinationPoint, completion: completion);
                                                        });
                                                    });
                                                }
                                                
                                            } else if (scandata.pingDistance < 15) && (scandata.pingDistance > 0) {
                                                self.bc.stopRangeScan({
                                                    self.logger.log(.Info, data: "scanSide: somethings in range: \(scandata)");
                                                    
                                                    self.bc.stopMovingWithPositionalUpdate({
                                                        self.bc.startUpdatingPosition(true, completion: { data in
                                                            self.avoidObstacle(destinationPoint, scanData: scanData, positionData: data, completion: completion);
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
                }else if (scandata.pingDistance < 10 && scandata.pingDistance != 0) {
                    self.bc.stopRangeScan({
                        self.logger.log(.Info, data: "scanFront: somethings in range: \(scandata)");
                        //                                self.avoidRight(destinationPoint, scanData: scanData, positionData: positionDataTmp);
                        self.bc.stopMovingWithPositionalUpdate({
                            self.avoidObstacle(destinationPoint, scanData: scanData, positionData: positionDataTmp, completion: completion);
                        });
                    });
                }
            });
        });

        //Alter Code auf den im Falle von Fehlern zurückgegriffen werden kann
        
        /*logger.log(.Info, data: "going to avoid to the left...");
        
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
        });*/
    }

    // diese Methode scannt links und rechts vom Roboter ob der Weg frei ist
    func scanLeftRight(completion: (left: Bool, right: Bool) -> ()) {
        logger.log(.Info, data: "check in which direction to avoid...");
        var leftDone = false;
        var rightDone = false;
        var leftFree = false;
        var rightFree = false;
        
//        Alter Code auf den im Falle von Fehlern zurückgegriffen werden kann
//
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
        
        // scannt in annähernd 180 grad vor dem Roboter
        self.bc.scanRange(0, max: 180, inc: 3, callback: { scandata in
            self.logger.log(.Info, data: "scanLeftRight: \(scandata)");
            
            // scannt links
            if(scandata.servoAngle < 90){
                if(scandata.pingDistance == 0.0){
                    leftFree = true;
                    leftDone = true;
                }else{
                    leftFree = false;
                }
                if (scandata.servoAngle < 25 ) {
                    leftDone = true;
                }
                
            // scannt rechts
            }else{
                if(scandata.pingDistance == 0.0){
                    rightFree = true;
                    rightDone = true;
                }else{
                    rightFree = false;
                }
                if (scandata.servoAngle > 155) {
                    rightDone = true;
                }
                
            }
            
            // wurden beide Richtungen gescannt bzw. sind beide frei, wird die Callback-Methode ausgeführt
            if(leftDone && rightDone){
                self.bc.stopRangeScan({
                    self.logger.log(.Info, data: "leftFree: \(leftFree), rightFree: \(rightFree)");
                    completion(left: leftFree, right: rightFree);
                });
            }
        });
    }
    
    // die Deinitialisierungsmethode
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self);
        logger.log(.Info, data: "✝ (rip) ✝");
    }
}