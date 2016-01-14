//
//  RaumvermesserViewController.swift
//  MobileBot
//
//  Created by Master on 22.12.15.
//  Copyright © 2015 Goran Vukovic. All rights reserved.
//

import Foundation
class RaumvermesserViewController: UIViewController {
    
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
    var timerDriveForSpace: NSTimer = NSTimer()

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
    var velocity: Float = 2
    var finished: Bool = false
    var log: Bool = true

    struct Wall {
        var ping: Float = 0
        var name: String = "No Name"
        var wall: Int = 0
        var wallChecked: Bool = false
        var length: Float = 0
        var points: [(x: Float,y: Float)] = Array()
        
        // gibt an ob sich Robo nach rechts oder links gedreht hat
        // wird benoetigt um aus den laengen punkte zu berechnen (fuer den grundriss)
        // wird in lengthToPoint benoetigt
        var turnLeft: Bool = true
        
        init(number: Int)
        {
            self.wall = number
        }
        
        init()
        {
            
        }
    }
    
    struct ScanData
    {
        var pingDistance: Float = 0
        var servoAngle: UInt8 = 0
        var frontPing: Float = 0
    }
    
    struct ScanValues
    {
        var min: UInt8 = 0
        var max: UInt8 = 0
        var inc: UInt8 = 0
        var wall: String = ""
    }
    
    var walls: [Wall] = []
    var scanData:ScanData = ScanData()
    
    var scanDirections:[ScanValues] = [ScanValues.init(min: 65, max: 90, inc: 2, wall: "Front"), ScanValues.init(min: 157, max: 180, inc: 2, wall: "Right")]
   
    
    @IBOutlet weak var labelFrontModulo: UILabel!
    @IBOutlet weak var labelCounter: UILabel!
    
    @IBOutlet weak var labelDistanceFront: UILabel!
    @IBOutlet weak var labelPingDistance: UILabel!
    @IBOutlet weak var labelServoAngle: UILabel!

    @IBOutlet weak var containerFloorPlan: UIView!
    
    
    func updateCounter() {
        counter++
        counterMod = counter % 4
        counterSingle++
        labelCounter.text = String(counter)
        labelFrontModulo.text = String(counterMod)
    }
    
    func initValues()
    {
        labelPingDistance.text = "0"
        labelServoAngle.text = "90"
        labelCounter.text = "0"
        labelFrontModulo.text = "0"
        labelDistanceFront.text = "0"
    }
    override func viewDidLoad() {
        super.viewDidLoad();
        initValues()
        
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
    @IBAction func startMeasure(sender: AnyObject) {
        if(finished == false){
            logger.log(.Info, data: "Start Action Raumvermesser");
            self.whichWall = 0
        
            self.timerCounter = NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector: Selector("updateCounter"), userInfo: nil, repeats: true)
        
            driveAndDetectWalls()
        }else{
            Toaster.show("Scan-Vorgang noch nicht beendet")
        }

    }
    
    @IBAction func stopMeasure(sender: AnyObject) {
        bc?.stopRangeScan({});
        timerCounter.invalidate()
        timerDrive.invalidate()
        timerScanRight.invalidate()
        timerScanFront.invalidate()

        counter = 0
        counterMod = 0
        labelCounter.text = String(counter)
        labelFrontModulo.text = String(counter)
        
    }
    
    func driveAndDetectWalls(){
        // in scane Range angegeben über min und max das auf der rechten Seite des Roboters immer ein Hindernis zu erkennen sein soll
        if(self.walls.count == 0)
        {
            self.whichWall = 0
        }
        else
        {
            self.whichWall = Int(self.walls.count)
        }
        
        print(self.walls.count)
        if(stopMoving == true)
        {
            // Check first Wall
            if(self.whichWall <= 3)
            {
                self.stopOrDrive("yes")
                //scanWallAndFront(walls[0].wallChecked)
                self.timerScanFront = NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector: Selector("checkFront"),
                    userInfo: nil, repeats: false)

            }
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
        self.bc?.scanRange(160, max: 180, inc: 10, callback: { data in
            
            self.labelDistanceFront.text = String(data.pingDistance)
            self.labelServoAngle.text = String(data.servoAngle)
        });
    }
    
    
    let mainQueue = dispatch_get_main_queue()
    let taskGroup = dispatch_group_create()

    func checkFront()
    
    {
        printText("checkFront()");
        //var tempWall: Wall = Wall(number: whichWall)
        var tempWall: Wall = Wall()
        
        self.bc?.scanRange(45, max: 200, inc: 2, callback: { data in
            
            self.labelDistanceFront.text = String(data.pingDistance)
            self.labelServoAngle.text = String(data.servoAngle)
            
            if(data.pingDistance <= 10 && data.pingDistance > 3 && data.servoAngle <= 80 && data.servoAngle >= 45)
            {
                
                dispatch_group_async(self.taskGroup, self.mainQueue, {[weak self] in

                
                self!.labelPingDistance.text = String(data.pingDistance)

                // Wand gefunden -> Aktuelle Wand updaten (walls[x]....)
                self!.foundWallFront = true
                self!.stopTimerScan()
                self!.stopRangeScan()
                self!.stopOrDrive("no")
                tempWall.name = String(self!.whichWall)
                tempWall.ping = data.pingDistance
                tempWall.wallChecked = true
                tempWall.length = self!.calcWallLength()
                
                self!.updateWallValue(tempWall, i: self!.whichWall)
                
                self!.turnLeft()
                self!.stopOrDrive("yes")

                           });
            
                if(self.whichWall < 4){
                    

                    
                    
                    dispatch_group_async(self.taskGroup, self.mainQueue, {[weak self] in
                            self!.timerDrive = NSTimer.scheduledTimerWithTimeInterval(8, target:self!, selector: Selector("driveAndDetectWalls"),
                                userInfo: nil, repeats: false)
                        
                        });
                    
                    
                }else{
                    self.finished = true
                    //self.draw()
                    
                    for x in self.walls
                    {
                        print(x)
                    }
                }
                
            }
            
            // @TODO
            if (data.servoAngle >= 150 && data.pingDistance >= 50 && data.pingDistance > 3)
            {
                // Biege rechts ab.....
                
//                Toaster.show("Gefunden")
//                self.driveForwardForSpace()
//                self.timerDriveForSpace = NSTimer.scheduledTimerWithTimeInterval(10, target:self, selector: Selector("stopSpaceDriving"),userInfo: nil, repeats: false)
//                //self.stopTimerScan()
//                self.stopRangeScan()
//
//                self.turnRight()
//                
//                self.driveForwardForSpace()
//
//                // Rechte Wand....
                
                
            }
        });
    }
    
    //@todo benoetigen turntoright funktion
    // die dann den wert wall.turntoleft auf false setzt
    func turnLeft( )
    {
        if let bn = bn {                   //bn.turnSpeed
            bn.turnToAngle(Float(90), speed: Float(15), completion: { [weak self] data in
                self!.bc?.resetPosition({[weak self] data in  });
                //self!.bc?.resetForwardKincematics({[weak self] data in  });
                });
        }

    }
    
    func turnRight( )
    {
        if let bn = bn {                   //bn.turnSpeed
            bn.turnToAngle(Float(-150), speed: Float(15), completion: { [weak self] data in
                self!.bc?.resetPosition({[weak self] data in  });
                //self!.bc?.resetForwardKincematics({[weak self] data in  });
                });
        }
        
    }
    
    func driveForwardForSpace()
    {
        bc?.move(self.velocity, omega: 0, completion: nil);
        
        
    }
    
    func stopSpaceDriving()
    {
        bc?.move(0, omega: 0, completion: nil);
    }
    
    func stopOrDrive(move: String)
    {
        printText("stopOrDrive()");
        switch(move)
        {
            case "yes":
                printText("stopOrDrive() yes");
                bc?.move(self.velocity, omega: 0, completion: nil);
            break

            case "no":
                printText("stopOrDrive() no");
                bc?.move(0, omega: 0, completion: nil);
            break
            
        default:
            break
        }
    }
    
    func stopRangeScan()
    {
        self.bc?.stopRangeScan({ [weak self] in
            self?.logger.log(.Info, data: "scan stopped")
            });
    }
    
    func stopTimerScan()
    {
        self.timerScanRight.invalidate()
        self.timerDrive.invalidate()
        self.timerScanFront.invalidate()
        self.counterSingle = 0
    }
    
    func updateWallValue(wall: Wall, i: Int)
    {
        printText("updateWallValue int: "+String(i));
        if(self.whichWall <= 3){
            walls.append(wall)
            printText("Wall Updated!")
            printText("Wall: " + self.walls[i].name)
            printText("Distance: " + String(self.walls[i].ping))
            printText("Wall Number: " + String(self.walls[i].wall))
            printText("Wall Checked: " + String(self.walls[i].wallChecked))
            self.whichWall++
            printText("Next Wall ->" + String(self.whichWall))
        }
    }
    
    func calcWallLength()-> Float{
        //annhame: velocity: (float, cm/s)
        //@todo pingdistance hinzufügen
        var length: Float = self.velocity * Float(self.counterSingle)
        printText("Wall Length: "+String(length))
        
        return length
    }
    
    
    
    func draw(){
        let imageSize = CGSize(width: 100, height: 200)
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 100, y: 100), size: imageSize))
        //self.view.addSubview(imageView)
        let image = drawCustomImage(imageSize)
        imageView.image = image
        
        self.containerFloorPlan.addSubview(imageView)
    }
    
    
    func drawCustomImage(size: CGSize) -> UIImage {
        // Setup our context
        let bounds = CGRect(origin: CGPoint.zero, size: size)
        let opaque = false
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let context = UIGraphicsGetCurrentContext()
        
        // Setup complete, do drawing here
        CGContextSetStrokeColorWithColor(context, UIColor.redColor().CGColor)
        CGContextSetLineWidth(context, 2.0)
        
        //CGContextStrokeRect(context, bounds)
        
        CGContextBeginPath(context)
        
        CGContextMoveToPoint(context, 0, 0)
        
        for var i = 0; i < self.walls.count; ++i {
            
            let length: Float = self.walls[i].length
            
            
            //CGContextAddLineToPoint(context, 100,0)
            
        }
        
        CGContextStrokePath(context)
        
        // Drawing complete, retrieve the finished image and cleanup
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    //@todo fertig machen
    func lengthToPoint(wall: Wall){
        //wall.length
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