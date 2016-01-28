//
//  RaumvermesserViewController.swift
//  MobileBot
//
//  Created by Master on 22.12.15.
//  Copyright © 2015 Goran Vukovic. All rights reserved.
//

import Foundation
class TestumgebungViewController: UIViewController {
    
    var bc: BotController?;
    var bn: BotNavigator?;
    let bcm = BotConnectionManager.sharedInstance();
    let logger = StreamableLogger();
    var debounceTimer: NSTimer?
    var notification: UILocalNotification?;
    
    
    @IBOutlet weak var labelPingDistance: UILabel!
    @IBOutlet weak var labelServoAngle: UILabel!
    @IBOutlet weak var labelSliderAngle: UILabel!
    @IBOutlet weak var labelSliderMin: UILabel!
    @IBOutlet weak var labelSliderMax: UILabel!
    @IBOutlet weak var sliderAngle: UISlider!
    @IBOutlet weak var sliderMin: UISlider!
    @IBOutlet weak var sliderMax: UISlider!
    
    @IBOutlet weak var labelSpeedTurn: UILabel!
    @IBOutlet weak var sliderTurn: UISlider!
    @IBOutlet weak var labelTurn: UILabel!
    
    @IBOutlet weak var sliderSpeedTurn: UISlider!
    @IBOutlet weak var sliderAngleTurn: UISlider!
     override func viewDidLoad() {
        super.viewDidLoad();
        
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
    
    func initValues()
    {
        labelSliderAngle.text = "1"
        labelSliderMax.text = "90"
        labelSliderMin.text = "90"
        labelSpeedTurn.text = "15"
        labelTurn.text = "180"
    }
    
    override func viewDidAppear(animated: Bool)
    {
        initValues()
    }
    
    func reset(){
        self.bc?.resetPosition({ () -> Void in
            self.logger.log(.Info, data: "Reset Robo Position");
        });
    }

    @IBAction func stopMeasure(sender: AnyObject) {
        bc?.stopRangeScan({});
    }
    
    
    func turnLeft()
    {
        let degrees: Float = 45;
        if let bn = bn {                   //bn.turnSpeed
            bn.turnToAngle(degrees, speed: 150, completion: { [weak self] data in
                });
        }

    }

    func stopRangeScan()
    {
        self.bc?.stopRangeScan({ [weak self] in
            self?.logger.log(.Info, data: "scan stopped")
            });
    }
    

    /*********** Test Values ********************/
    @IBAction func tryButton(sender: AnyObject)
    {
        self.bc?.scanRange(UInt8(sliderMin.value), max: UInt8(sliderMax.value), inc: UInt8(sliderAngle.value), callback: { scandata in
            self.labelServoAngle.text = String(format: "%.00f", scandata.servoAngle) + "°"
            self.labelPingDistance.text = String(format: "%.02f", scandata.pingDistance)
        });
        
        
    }

    @IBAction func sliderMinChange(sender: AnyObject) {
        labelSliderMin.text = String(format: "%.02f", sliderMin.value) + "°"
    }


    @IBAction func sliderAngleChange(sender: AnyObject) {
        labelSliderAngle.text = String(format: "%.00f", sliderAngle.value) + "°"
    }

 
    @IBAction func sliderMaxChange(sender: AnyObject)
    {
        labelSliderMax.text = String(format: "%.02f", sliderMax.value) + "°"
    }
    /********** END ******************************/
    
    @IBAction func doTurn(sender: AnyObject)
    {
        if let bn = bn {                   //bn.turnSpeed
            bn.turnToAngle(Float(self.sliderAngleTurn.value), speed: Float(self.sliderSpeedTurn.value), completion: { [weak self] data in
                self!.bc?.resetPosition({[weak self] data in  });
                self!.bc?.resetForwardKincematics({[weak self] data in  });
                });
        }

    }
    @IBAction func undoTurn(sender: AnyObject)
    {
        if let bn = bn {                   //bn.turnSpeed
            bn.turnToAngle(Float((-1)*self.sliderAngleTurn.value), speed: Float(self.sliderSpeedTurn.value), completion: { [weak self] data in
                self!.bc?.resetPosition({[weak self] data in  });
                self!.bc?.resetForwardKincematics({[weak self] data in  });
                });
        }
    }
    
    @IBAction func sliderAngleTurn(sender: AnyObject)
    {
        self.labelTurn.text = String(format: "%.00f", self.sliderAngleTurn.value)
    }
    @IBAction func speedTurn(sender: AnyObject)
    {
        self.labelSpeedTurn.text = String(format: "%.00f", self.sliderSpeedTurn.value)
    }
    @IBAction func do90(sender: AnyObject)
    {
        self.sliderAngleTurn.value = 90.0
    }
    @IBAction func doM90(sender: AnyObject)
    {
        self.sliderAngleTurn.value = -90.0
    }
}

