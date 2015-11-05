//
//  SecondViewController.swift
//  MobileBot
//
//  Created by Goran Vukovic on 22.10.15.
//  Copyright © 2015 Goran Vukovic. All rights reserved.
//

import UIKit

class TestHardwareController: UIViewController {

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
    
    var timer = NSTimer()
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        if bcm.connections.count <= 0 {
            Toaster.show("Please provide at minimum a single connection inside the settings.");
        } else {
            if let connection = bcm.connections[0] as? BotConnection {
                bc = BotController(connection: connection);
                
                if let bc = bc {
                    bn = BotNavigator(controller: bc);
                    
                    /*
                    speedField.text = String(stringInterpolationSegment: bn!.getSpeed());
                    turnSpeedField.text = String(stringInterpolationSegment: bn!.getTurnSpeed());
                    offsetField.text = String(stringInterpolationSegment: bn!.getOffset());
                    */
                }
                
                bcm.connect(connection);
            }
        }
    }
    
    @IBAction func testMovement(sender: UIButton)
    {
        timer = NSTimer.scheduledTimerWithTimeInterval(0.0, target: self, selector: "testForward", userInfo: nil, repeats: false)
        Toaster.show("Next Test")
        timer = NSTimer.scheduledTimerWithTimeInterval(4.0, target: self, selector: "testBackwards", userInfo: nil, repeats: false)
        Toaster.show("Next Test")
        timer = NSTimer.scheduledTimerWithTimeInterval(8.0, target: self, selector: "testLeft", userInfo: nil, repeats: false)
        Toaster.show("Next Test")
        timer = NSTimer.scheduledTimerWithTimeInterval(12.0, target: self, selector: "testRight", userInfo: nil, repeats: false)
        Toaster.show("Next Test")
        timer = NSTimer.scheduledTimerWithTimeInterval(16.0, target: self, selector: "testScan", userInfo: nil, repeats: false)
        Toaster.show("Testing Done")
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
    
    func testForward()
    {
        //logger.log(.Info, data: "Test: Moving Forward")
        Toaster.show("Test: Moving Forward")
        
        bc?.move(15, omega: 0, completion: nil);
        timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "timerStop", userInfo: nil, repeats: false)
    }
    
    func testBackwards()
    {
        //logger.log(.Info, data: "Test: Moving Backwards")
        Toaster.show("Test: Moving Backwards")
        
        bc?.move(-15, omega: 0, completion: nil);
        timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "timerStop", userInfo: nil, repeats: false)
    }
    
    func testLeft()
    {
        //logger.log(.Info, data: "Test: Rotate Left")
        Toaster.show("Test: Rotate Left")
        
        let degrees: Float = 45;
        if let bn = bn {                   //bn.turnSpeed
            bn.turnToAngle(degrees, speed: 150, completion: { [weak self] data in
                self?.logger.log(.Info, data: "finished");
                });
        }
        timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "timerStop", userInfo: nil, repeats: false)
    }
    
    func testRight()
    {
        //logger.log(.Info, data: "Test: Rotate Right")
        Toaster.show("Test: Rotate Right (Speed x 2)")
        
        let degrees: Float = -45;
        if let bn = bn {
            bn.turnToAngle(degrees, speed: 300, completion: { [weak self] data in
                self?.logger.log(.Info, data: "finished");
                });
        }
        timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "timerStop", userInfo: nil, repeats: false)
    }
    
    func testScan()
    {
        Toaster.show("Test: Scan")

        bc?.scanRange(75, max: 125, inc: 3, callback: { [weak self] data in
            self?.logger.log(.Info, data: "\(data)")
            });
        timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "stopRangeScan", userInfo: nil, repeats: false)

    }

    func stopRangeScan()
    {
        bc?.stopRangeScan({ [weak self] in
            self?.logger.log(.Info, data: "scan stopped")
            });
    }
    

    func timerStop()
    {
        bc?.stopMovingWithPositionalUpdate({ [weak self] in
            //self?.logger.log(.Info, data: "stopped");
            
            self?.bc?.startUpdatingPosition(true, completion: { data in
                //self?.logger.log(.Info, data: "current position: \(data)");
            });
            });
        
        bc?.stopRangeScan({});
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

