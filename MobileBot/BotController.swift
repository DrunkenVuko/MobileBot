//
//  BotController.swift
//  iRobot
//
//  Created by leemon20 on 01.06.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

import Foundation

typealias PingSensorData        = (pingDistance: Float, servoAngle: UInt8, servoEnabled: UInt8);
typealias ForwardKinematicsData = (x: Float, y: Float, phi: Float);

class BotController {
        
    let logger = StreamableLogger();
    
    var connectionStatus: BotConnectionConnectionStatus {
        get {
            return connection.connectionStatus;
        }
    };
    
    // Command operators
    private var connection: BotConnection;
    private let cq = CommandQueue();
    
    // flags
    private var shouldUpdatePosition = false;
    private var shouldScanRange      = false;
    
    // Timer reference
    private var timer: NSTimer?;
    
    // ************************************
    // MARK: Initializers
    // ************************************
    
    init(connection: BotConnection) {
        self.connection = connection;
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "connected:", name: "BotConnectionConnected", object: connection);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "disconnected:", name: "BotConnectionDisconnected", object: connection);
        
        if connection.connectionStatus == .Connected {
            connected(nil);
        }
    }
    
    // ************************************
    // MARK: Notifications
    // ************************************
    
    @objc func connected(notification: NSNotification?) {
        logger.log(.Info, data: "connected");
        
        timer = NSTimer.scheduledTimerWithTimeInterval(0.016, target: self, selector: "executeNextCommand", userInfo: nil, repeats: true);
    }
    
    @objc func disconnected(notification: NSNotification?) {
        logger.log(.Info, data: "disconnected");
        
        if let timer = timer {
            timer.invalidate();
        }
    }
    
    // ************************************
    // MARK: Control Methods
    // ************************************
    
    /**
     * Use `startMovingWithPositionalUpdate` instead. Starts moving the Bot.
     *
     * - parameter velocity: Bot velocity
     * - parameter omega: Bot omega (turn speed)
     * - parameter completion: Completion handler to be executed on finish
     */
    func move(velocity: Float, omega: Float, completion: (() -> Void)? ) {
        logger.log(.Info, data: "moving: \(velocity): \(omega)");
        
        let sbv = ProtocolCommand(
            key: ProtocolCommandKey.SetBotVelocity,
            fields:
            [
                ProtocolCommandField(name: "botSpeedForward", value: velocity, valueType:.Float),
                ProtocolCommandField(name: "botSpeedOmega", value: omega, valueType:.Float)
            ]
        );
        
        self.cq.enqueueCommand(Command(command: sbv, onSuccess: {cmd in
            self.logger.log(.Info, data: "\(cmd)");
            
            completion?();
        }));
    }
    
    /**
     * Stops moving the bot. !!! Important !!! call `stoptUpdatingPosition` before calling `stop`
     *
     * - parameter callback: Funktion to be called on finish
     */
    func stop(completion: (() -> Void)? ) {
        logger.log(.Info, data: "stopping...");
        
        move(0, omega: 0, completion: completion);
    }
    
    /**
     * Starts moving the Bot and delivers positional updates through the callback
     *
     * - parameter velocity: Bot velocity
     * - parameter omega: Bot omega (turn speed)
     * - parameter callbacl: Delivers positional updates
     */
    func startMovingWithPositionalUpdate(velocity: Float, omega: Float, callback: ForwardKinematicsData -> Void) {
        logger.log(.Info, data: "starting movement and positional update...");
        
        move(velocity, omega: omega, completion: {
            self.logger.log(.Info, data: "starting positional update...");

            self.startUpdatingPosition(completion: callback);
        });
    }
    
    /**
     * Stops moving the bot and delivering positional updates
     *
     * - parameter callback: Funktion to be called on finish
     */
    func stopMovingWithPositionalUpdate(completion: (() -> Void)? ) {
        logger.log(.Info, data: "stopping movement and positional update");
        
        stoptUpdatingPosition();

        stop(completion);
    }
    
    /**
     * Starts updating the current Bots position. Delivers received data to the caller through the callback. 
     * !!! Important !!! call `stoptUpdatingPosition`
     *
     * - parameter callback: Funktion to be called everytime a new value is received
     */
    func startUpdatingPosition(once: Bool = false, completion: (ForwardKinematicsData) -> Void) {
        logger.log(.Info, data: "getting current position...");
        
        shouldUpdatePosition = !once;
        
        let gfk = ProtocolCommand(
            key: ProtocolCommandKey.GetForwardKinematics,
            fields: []
        );
        
        // final command for observing passed distance
        let gfkCommand = Command(command: gfk);
        
        let onGFKSuccess: CommandSuccessHandler = {cmd in
            
            let xtField   = cmd.fields[0] as! ProtocolCommandField;
            let ytField   = cmd.fields[1] as! ProtocolCommandField;
            let phitField = cmd.fields[2] as! ProtocolCommandField;
            
            let data: ForwardKinematicsData = (x:xtField.value.floatValue, y: ytField.value.floatValue, phi: phitField.value.floatValue);
            
            self.logger.log(.Info, data: "GetForwardKinematics: \(data)");
            
            completion(data);
            
            if self.shouldUpdatePosition {
                self.cq.enqueueCommand(gfkCommand);
            }
        };
        gfkCommand.onSuccess = onGFKSuccess;
        
        // enqueue final command
        self.cq.enqueueCommand(gfkCommand);
    }
    
    /**
     * Stops updating the current Bots position.
     *
     * - parameter callback: Funktion to be called on success
     */
    func stoptUpdatingPosition() {
        self.shouldUpdatePosition = false;
    }
    
    func resetBotDynamics(completion: (() -> Void)? ) {
        let rbd = ProtocolCommand(
            key: ProtocolCommandKey.ResetBotDynamics,
            fields: []
        );
        
        cq.enqueueCommand(Command(command: rbd, onSuccess: { cmd in
            self.logger.log(.Info, data: "reseted bot dynamocs: \(cmd)");
            
            completion?();
        }));
    }
    
    func resetForwardKincematics(completion: (() -> Void)? ) {
        let sfk = ProtocolCommand(
            key: ProtocolCommandKey.SetForwardKinematics,
            fields:
            [
                ProtocolCommandField(name: "xt", value: NSNumber(float: 0), valueType:.Float),
                ProtocolCommandField(name: "yt", value: NSNumber(float: 0), valueType:.Float),
                ProtocolCommandField(name: "phit", value: NSNumber(float: 0), valueType:.Float)
            ]
        );
        
        cq.enqueueCommand(Command(command: sfk, onSuccess: { cmd in
            self.logger.log(.Info, data: "\(cmd)");
            
            completion?();
        }));
    }
    
    func resetPosition(completion: (() -> Void)? ) {
        logger.log(.Info, data: "going to reset bot dynamics and forward kinematics");
        
        resetBotDynamics({
            self.resetForwardKincematics({
                self.logger.log(.Info, data: "bot dynamics and forward kinematics reseted");
                
                completion?();
            });
        });
    }
    
    /**
     * Starts scanning specified range by min and max. Delivers received data to the caller through the callback
     *
     * - parameter min: Minimal range to scan
     * - parameter max: Maximum range to scan
     * - parameter inc: Increment between each step
     * - parameter callback: Funktion to be called everytime a new value is received
     */
    func scanRange(min: UInt8, max: UInt8, inc: UInt8, callback: PingSensorData -> Void) {
        logger.log(.Info, data: "starting range scan... with min: \(min), max: \(max), inc: \(inc)");
        
        // raw servo command
        let ssar = ProtocolCommand(
            key: ProtocolCommandKey.SetServoAngleRange,
            fields:
            [
                ProtocolCommandField(name: "servoAngleRangeMin", value: NSNumber(unsignedChar: min), valueType:.UnsignedChar),
                ProtocolCommandField(name: "servoAngleRangeMax", value: NSNumber(unsignedChar: max), valueType:.UnsignedChar),
                ProtocolCommandField(name: "servoAngleRangeInc", value: NSNumber(unsignedChar: inc), valueType:.UnsignedChar)
            ]
        );
        
        // raw get ping sensor values command
        let gpsv = ProtocolCommand(
            key: ProtocolCommandKey.GetPingSensorValue,
            fields: []
        );
        
        // composed command
        let gpsvCommand = Command(command: gpsv);
        let onSuccess: CommandSuccessHandler = { cmd in
            
            if self.shouldScanRange {
                self.logger.log(.Info, data: "\(cmd)")
                
                let pingDistanceField = cmd.fields[0] as! ProtocolCommandField;
                let servoAngleField   = cmd.fields[1] as! ProtocolCommandField;
                let servoEnabledField = cmd.fields[2] as! ProtocolCommandField;
                
                let data: PingSensorData = (pingDistance: pingDistanceField.value.floatValue, servoAngle: servoAngleField.value.unsignedCharValue, servoEnabled: servoEnabledField.value.unsignedCharValue);
                
                callback(data);
                
                self.cq.enqueueCommand(gpsvCommand);
            }
        };
        gpsvCommand.onSuccess = onSuccess;
        
        // enqueue both commands for execution
        cq.enqueueCommand(Command(command: ssar, onSuccess: { cmd in
            self.shouldScanRange = true;
            
            self.cq.enqueueCommand(gpsvCommand);
            
        }));
    }
    
    func stopRangeScan(callback: () -> ()) {
        self.shouldScanRange = false;
        
        let ssar = ProtocolCommand(
            key: ProtocolCommandKey.SetServoAngleRange,
            fields:
            [
                ProtocolCommandField(name: "servoAngleRangeMin", value: NSNumber(unsignedChar: 90), valueType:.UnsignedChar),
                ProtocolCommandField(name: "servoAngleRangeMax", value: NSNumber(unsignedChar: 90), valueType:.UnsignedChar),
                ProtocolCommandField(name: "servoAngleRangeInc", value: NSNumber(unsignedChar: 0), valueType:.UnsignedChar)
            ]
        );
        
        cq.enqueueCommand(Command(command: ssar, onSuccess: { cmd in
            self.logger.log(.Info, data: "\(self.shouldScanRange)");
            
            callback();
        }));
    }
    
    // ************************************
    // MARK: Command Transmission
    // ************************************
    
    @objc func executeNextCommand() {
        if !connection.isExecutingCommand() && connectionStatus == .Connected {
            let cqd = cq.dequeueCommand();
            
            if cqd.command.key != .None {
                logger.log(.Off, data: "executing next command: \(cqd.command.simpleDescription())");
            }

            connection.executeCommand(cqd.command, completion: { (response, error) -> Void in
                if error == nil {
                    self.logger.log(.Off, data: "\(cqd.command.simpleDescription()):\(cqd.predicate) executed successful. response: \(response.simpleDescription())");
                    
                    if let onSuccess = cqd.onSuccess {
                        onSuccess(response);
                    }
                    
                } else {
                    self.logger.log(.Off, data: "\(cqd.command.simpleDescription()):\(error.localizedFailureReason)");
                }
            });
        } else {
            logger.log(.Off, data: "not able to execute next command (\(self.connection.isExecutingCommand()), \(self.connectionStatus), \(self.connection.pceu))");
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self);
        
        logger.log(.Info, data: "✝ (rip) ✝");
    }
}












