//
//  RaumvermesserViewController.swift
//  MobileBot
//
//  Created by Master on 22.12.15.
//  Copyright © 2015 Goran Vukovic. All rights reserved.
//

import Foundation
class WatchdogViewController: UIViewController {
    
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
    
    // Zeit
    var counter = 0
    // Zeit fuer eine einzelne Wand
    var counterSingle = 0
    var counterMod = 0
    
    // Kontrollvariablen
    var frontScan: Bool = true
    var stopMoving: Bool = true
    var foundWallFront: Bool = false
    var pingFront: Float = 0.0
    var whichWall: Int = 0
    var finished: Bool = false
    var log: Bool = true

    // Neue 100% Sichere Vars
    var posDoorRightX: Int = 50
    var posDoorRightY: Int = -180
    var timerDriveRight: NSTimer = NSTimer()
    var velocity: Float = 10

    @IBOutlet weak var labelDistanceFront: UILabel!
    @IBOutlet weak var labelServoAngle: UILabel!
    
    
    
    
    func updateCounter() {
//        counter++
//        counterMod = counter % 4
//        counterSingle++
//        labelCounter.text = String(counter)
//        labelFrontModulo.text = String(counterMod)
    }
    
    func initValues()
    {
        labelServoAngle.text = "90"
        labelDistanceFront.text = "0"
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
        
        //draw()
        
    }
    
    override func viewDidAppear(animated: Bool)
    {
        
    }
    
    func reset(){
        self.bc?.resetPosition({ () -> Void in
            self.logger.log(.Info, data: "Reset Robo Position");
        });
    }
    
    
    // Raumvermesser App wird über Button "Vermessen" gestartet
    @IBAction func startWatch(sender: AnyObject) {
        if(finished == false){
            reset()
            logger.log(.Info, data: "Start Action Watchdog");
            //self.whichWall = 0
            
            self.timerCounter = NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector: Selector("updateCounter"), userInfo: nil, repeats: true)

            driveAndDetect()
            
        }else{
            Toaster.show("Scan-Vorgang noch nicht beendet")
        }
        
    }
    
    // Raumvermesser App wird über Button "Vermessen" gestartet
    @IBAction func endWatch(sender: AnyObject) {
        if(finished == false){
            //reset()
            logger.log(.Info, data: "Start Action Watchdog");

            self.driveHome()
            
        }else{
            Toaster.show("Scan-Vorgang noch nicht beendet")
        }
        
    }
    
    @IBAction func stopMeasure(sender: AnyObject) {
        bc?.stopRangeScan({});
        bc?.stop({})
        timerCounter.invalidate()
        timerDrive.invalidate()
        timerScanRight.invalidate()
        timerScanFront.invalidate()
        
        counter = 0
        counterMod = 0

        
    }
    
    func driveAndDetect(){
        // in scane Range angegeben über min und max das auf der rechten Seite des Roboters immer ein Hindernis zu erkennen sein soll
        if(stopMoving == true)
        {
            //turnRight()
            /*timerDriveRight = NSTimer.scheduledTimerWithTimeInterval(8.0, target: self, selector: "drive", userInfo: nil, repeats: false)*/
            drive()
            self.timerScanFront = NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector: Selector("checkFrontToDoor"),userInfo: nil, repeats: true)
//
         //            //scanWallAndFront(walls[0].wallChecked)

//
//            self.timerScanRight = NSTimer.scheduledTimerWithTimeInterval(4, target:self, selector: Selector("checkRight"),
//                userInfo: nil, repeats: true)
//                
            
        }
        
    }
    
    /*********** Scan the Front and the Right ********************
     - Wiederholende Funktion (0.9 Sekunden)
     - 3 Sekunden Scan der Front
     - 1 Sekunde Scan der Wand Rechts
     - Ping wird nur für Vorne aktualisiert
     - Bei Wand -> Stop */
    
    
    func checkRight()
    {
        printText("checkRight()");
        //bc?.scanRange(75, max: 90, inc: 3, callback: { [weak self] data in
        self.bc?.scanRange(170, max: 180, inc: 10, callback: { data in
            
            self.labelDistanceFront.text = String(data.pingDistance)
            self.labelServoAngle.text = String(data.servoAngle)
        });
    }
    
    func checkFrontToDoor()
        
    {
        printText("checkFrontToDoor()");
        
        self.bc?.scanRange(85, max: 95, inc: 5, callback: { data in
            
            self.labelDistanceFront.text = String(data.pingDistance)
            self.labelServoAngle.text = String(data.servoAngle)
            
            if(data.pingDistance <= 20 && data.pingDistance > 5)
            {
                self.stop()
                self.stopTimerScan()
                self.stopRangeScan()
                
                self.turnLeft()
                
                self.timerDriveRight = NSTimer.scheduledTimerWithTimeInterval(8.0, target: self, selector: "checkFrontForEvent", userInfo: nil, repeats: false)

            }
        });
    }
    
    func checkFrontForEvent()
        
    {
        printText("checkFrontForEvent()");
        
        self.bc?.scanRange(85, max: 95, inc: 5, callback: { data in
            
            self.labelDistanceFront.text = String(data.pingDistance)
            self.labelServoAngle.text = String(data.servoAngle)
            
            if(data.pingDistance <= 50 && data.pingDistance > 5)
            {

                self.stopTimerScan()
                self.stopRangeScan()
                
                self.driveHome()
                
            }
        });
    }
    
    func checkFrontToHome()
        
    {
        printText("checkFrontToHome()");
        
        self.bc?.scanRange(85, max: 95, inc: 5, callback: { data in
            
            self.labelDistanceFront.text = String(data.pingDistance)
            self.labelServoAngle.text = String(data.servoAngle)
            
            if(data.pingDistance <= 20 && data.pingDistance > 5)
            {
                self.stop()
                self.stopTimerScan()
                self.stopRangeScan()
                
                self.turnRight()
                
            }
        });
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
    
    
    
    
    
}

//timer = NSTimer.scheduledTimerWithTimeInterval(16.0, target: self, selector: "testScan", userInfo: nil, repeats: false)
//
//@IBAction func stop(sender: UIButton) {
//    bc?.stopMovingWithPositionalUpdate({ [weak self] in
//        self?.logger.log(.Info, data: "stopped");
//
//        self?.bc?.startUpdatingPosition(true, completion: { data in
//            self?.logger.log(.Info, data: "current position: \(data)");
//        });
//        });
//    
//    bc?.stopRangeScan({});

//    bc?.move(15, omega: 0, completion: nil);