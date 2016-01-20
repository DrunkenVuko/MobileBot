//
//  BabyDogViewController.swift
//  MobileBot
//
//  Created by Master on 14.01.16.
//  Copyright © 2016 Goran Vukovic. All rights reserved.
//

import Foundation

class BabyDogViewController:UIViewController{
    var bc: BotController?;
    var bn: BotNavigator?;
    let bcm = BotConnectionManager.sharedInstance();
    let logger = StreamableLogger();
    
    var debounceTimer: NSTimer?
    var notification: UILocalNotification?;
    
    var startPointX = 10;
    var startPointY = 10;
    
    // Timer
    var timerCounter: NSTimer = NSTimer()
    var timerScanFront: NSTimer = NSTimer()
    var timerScanRight: NSTimer = NSTimer()
    var timerDrive: NSTimer = NSTimer()
    var timerX: NSTimer = NSTimer()

    // Kontrollvariablen
    var stopMoving: Bool = true
    //var foundEntruder: Bool = false
    var pingFront: Float = 0.0
    var finished: Bool = false
    var log: Bool = true
    var someoneAtDoor :Bool = false
    
    // Neue 100% Sichere Vars
    var posDoorRightX: Int = 50
    var posDoorRightY: Int = -180
    var timerDriveRight: NSTimer = NSTimer()
    var velocity: Float = 10
    
    
    var a_velocity:Float = 15,
    stationRight:Float = 181,
    rightLeft:Float = 101,
    leftStation:Float = 206,
    
    a_stationRight:Float = -86,
    a_rightLeft:Float = 86,
    a_leftRight:Float = 180,
    
    t_stationRight:Double = 1.81,
    t_rightLeft:Double = 1.01
    
    @IBAction func startGuard(sender: AnyObject) {

    }
    
    
    @IBAction func startGuardPatrol(sender: AnyObject) {
        if(finished == false){
            reset()
            logger.log(.Info, data: "Start Action Guard and Patrol");
            //self.whichWall = 0
            
            turnRight90()
            self.timerScanRight = NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector: Selector("partolAndScan"), userInfo: nil, repeats: false)
            
        }else{
            Toaster.show("Guard and Patrol did not start")
        }
    }
    
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
                    //bn?.setLogger(false)
                    bcm.connect(connection);
                }
                
                //bc?.setLogger(false)
            }
        }
        
    }
    
    override func viewDidAppear(animated: Bool)
    {
        
    }
    
    func reset(){
        self.bc?.resetPosition({ () -> Void in
            self.logger.log(.Info, data: "Reset Robo Position");
        });
    }
    
    func patrolAndScan(){
        partol()
        timerDriveRight = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: "turnLeft", userInfo: nil, repeats: false)
        partol()
        timerDriveRight = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: "turnRight", userInfo: nil, repeats: false)
        }
    
    func partol(){
        self.bc?.move(self.velocity, omega: 0, completion: { data in
            self.logger.log(.Info, data: "baby move");
            self.timerCounter = NSTimer.scheduledTimerWithTimeInterval(self.t_stationRight, target:self, selector: Selector("stop"), userInfo: false, repeats: false)
        })
        
    }
    
    func scan() {
        var scanBugFlag = 0.0;
        self.bc?.scanRange(100, max: 150, inc: 3, callback: { scandata in
            self.logger.log(.Info, data: "scanning room entry \(scandata.pingDistance)");
            if (scandata.pingDistance < 40 && scandata.pingDistance > 0) {
                if (scanBugFlag >= 5.0){
                    self.logger.log(.Info, data: "intruder detected");
                    self.someoneAtDoor = true;
                    self.bc?.stopRangeScan({
                        self.bc?.stoptUpdatingPosition();
                        self.bc?.stop({
                            self.driveHome();
                        });
                    });
                    self.sendAlarm("Alarm!");
                    
                }else{
                    scanBugFlag++;
                }
            }else{
                scanBugFlag = 0.0;
            }
        })
    }
    
    func driveHome()
    {
        if(stopMoving == true)
        {
            turnLeft()
            timerDriveRight = NSTimer.scheduledTimerWithTimeInterval(8.0, target: self, selector: "drive", userInfo: nil, repeats: false)
            self.timerScanFront = NSTimer.scheduledTimerWithTimeInterval(3, target:self, selector: Selector("checkFrontToHome"),userInfo: nil, repeats: true)
        }
    }
    
    //@todo benoetigen turntoright funktion
    // die dann den wert wall.turntoleft auf false setzt
    func turnRight90( )
    {
        if let bn = bn {                   //bn.turnSpeed
            bn.turnToAngle(Float(-90), speed: Float(15), completion: { [weak self] data in
                self!.bc?.resetPosition({[weak self] data in  });
                //self!.bc?.resetForwardKincematics({[weak self] data in  });
                });
        }
        
    }
    
    func turnRight( )
    {
        if let bn = bn {                   //bn.turnSpeed
            bn.turnToAngle(Float(-180), speed: Float(15), completion: { [weak self] data in
                self!.bc?.resetPosition({[weak self] data in  });
                //self!.bc?.resetForwardKincematics({[weak self] data in  });
                });
        }
        
    }
    
    func turnLeft( )
    {
        if let bn = bn {                   //bn.turnSpeed
            bn.turnToAngle(Float(90), speed: Float(15), completion: { [weak self] data in
                self!.bc?.resetPosition({[weak self] data in  });
                //self!.bc?.resetForwardKincematics({[weak self] data in  });
                });
        }
        
    }
    
    func stop()
    {
        printText("stopOrDrive() no");
        bc?.move(0, omega: 0, completion: nil);
        
    }
    
    func drive()
    {
        
        printText("stopOrDrive() yes");
        bc?.move(self.velocity, omega: 0, completion: nil);
        
    }
    
    func stopRangeScan()
    {
        self.bc?.stopRangeScan({ [weak self] in
            self?.logger.log(.Info, data: "scan stopped")
            });
    }
    
    func stopTimerScan()
    {
        self.timerScanFront.invalidate()
        self.timerDriveRight.invalidate()
    }
    
    
    func printText(message: String){
        if(log){
            print(message)
        }
    }
    func sendAlarm(message: String){
        Toaster.show(message);
    }

}
