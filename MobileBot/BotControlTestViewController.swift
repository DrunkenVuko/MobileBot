//
//  BotControlTestViewController.swift
//  iRobot
//
//  Created by leemon20 on 02.06.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

import Foundation
import UIKit

class BotControlTestViewController : UIViewController {
    
    @IBOutlet weak var xField: UITextField!
    @IBOutlet weak var yField: UITextField!
    @IBOutlet weak var speedField: UITextField!
    @IBOutlet weak var turnSpeedField: UITextField!
    @IBOutlet weak var offsetField: UITextField!
    @IBOutlet weak var angleTextField: UITextField!
    
    var bc: BotController?;
    var bn: BotNavigator?;
    let bcm = BotConnectionManager.sharedInstance();
    let logger = StreamableLogger();
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        if bcm.connections.count <= 0 {
            Toaster.show("Please provide at minimum a single connection inside the settings.");
        } else {
            if let connection = bcm.connections[0] as? BotConnection {
                bc = BotController(connection: connection);
                
                if let bc = bc {
                    bn = BotNavigator(controller: bc);
                    
                    speedField.text = String(stringInterpolationSegment: bn!.getSpeed());
                    turnSpeedField.text = String(stringInterpolationSegment: bn!.getTurnSpeed());
                    offsetField.text = String(stringInterpolationSegment: bn!.getOffset());
                }
                
                bcm.connect(connection);
            }
        }
    }
    
    @IBAction func move(sender: UIButton) {
        logger.log(.Info, data: "going to move forward");
        
        bc?.move(15, omega: 0, completion: nil);
    }
    @IBAction func stop(sender: UIButton) {
        bc?.stopMovingWithPositionalUpdate({ [weak self] in
            self?.logger.log(.Info, data: "stopped");
            
            self?.bc?.startUpdatingPosition(true, completion: { data in
                self?.logger.log(.Info, data: "current position: \(data)");
            });
            });
        
        bc?.stopRangeScan({});
    }
    
    @IBAction func currentPosition(sender: UIButton) {
        bc?.startUpdatingPosition(true, completion: { [weak self] data in
            self?.logger.log(.Info, data: "current position: \(data)");
            });
    }
    
    @IBAction func turnToAngle(sender: UIButton) {
        let degrees: Float = Float(angleTextField.text!)!;
        
        if let bn = bn {
            bn.turnToAngle(degrees, speed: bn.turnSpeed, completion: { [weak self] data in
                self?.logger.log(.Info, data: "finished");
                });
        }
    }
    
    @IBAction func back(sender: UIBarButtonItem) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil);
    }
    
    @IBAction func scanRange(sender: UIButton) {
        bc?.scanRange(75, max: 125, inc: 3, callback: { [weak self] data in
            self?.logger.log(.Info, data: "\(data)")
            });
    }
    
    @IBAction func stopRangeScan(sender: UIButton) {
        bc?.stopRangeScan({ [weak self] in
            self?.logger.log(.Info, data: "scan stopped")
            });
    }
    
    @IBAction func resetPosition(sender: UIButton) {
        bc?.resetPosition({
            self.logger.log(.Info, data: "position reseted");
            
            self.bc?.startUpdatingPosition(true, completion: { [weak self] data in
                self?.logger.log(.Info, data: "current position: \(data)");
                });
        });
    }
    
    @IBAction func speedChanged(sender: UITextField) {
        bn?.setSpeed(NSString(string: speedField.text!).floatValue);
    }
    @IBAction func turnSpeedChanged(sender: UITextField) {
        bn?.setTurnSpeed(NSString(string: turnSpeedField.text!).floatValue)
    }
    @IBAction func offsetChanged(sender: UITextField) {
        bn?.setOffset(NSString(string: offsetField.text!).floatValue)
    }
    
    // BotNavigator
    @IBAction func moveToPoint(sender: UIButton) {
        bn?.moveTo(CGPointMake(CGFloat(NSString(string: xField.text!).floatValue), CGFloat(NSString(string: yField.text!).floatValue)), completion: nil);
    }
    
    deinit {
        logger.log(.Info, data: "✝ (rip) ✝");
    }
}