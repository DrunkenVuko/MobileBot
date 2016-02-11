//
//  RaumvermesserBot.swift
//  MobileBot
//
//  Created by Bianca Ciuperca-Baier, Leonie Wismeth, Goran Vukovic on 20.12.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

import Foundation
import AVFoundation

/**
 * Class for Use Case : RaumvermesserBot
 */
class RaumvermesserBot: UIViewController {
    
    var bc: BotController?;
    var bn: BotNavigator?;
    let bcm = BotConnectionManager.sharedInstance();
    let logger = StreamableLogger();
    
    
    // NSUserDefaults
    let prefs = NSUserDefaults.standardUserDefaults()
    
    // Timer
    var timerCounter: NSTimer = NSTimer()
    var timerScanFront: NSTimer = NSTimer()
    var timerScanRight: NSTimer = NSTimer()
    var timerDrive: NSTimer = NSTimer()
    var timerDriveForSpace: NSTimer = NSTimer()
    
    //container
    let containerWidth: CGFloat = 360
    let containerHeight: CGFloat = 290
    
    // counter
    var counter = 0
    var counterSingle = 0
    var counterMod = 0
    
    // control attributes
    var whichWall: Int = 0
    var velocity: Float = 5
    var finished: Bool = true
    var pingDistance: Float = 0
    
    struct Wall {
        //wall ping distance
        var ping: Float = 0
        var item: Int = 0
        var length: Float = 0
        var points: [(x: Float,y: Float)] = Array()
        
        init(){}
        
        init(length: Float){
            self.length = length
        }
    }
    
    struct ScanData{
        var pingDistance: Float = 0
        var servoAngle: UInt8 = 0
        var frontPing: Float = 0
    }
    
    struct ScanValues{
        var min: UInt8 = 0
        var max: UInt8 = 0
        var inc: UInt8 = 0
        var wall: String = ""
    }
    
    var walls: [Wall] = []
    
    //var walls: [Wall] = [Wall.init(length: 90), Wall.init(length: 95), Wall.init(length: 90), Wall.init(length: 95)]
    
    var scanData:ScanData = ScanData()
    
    var scanDirections:[ScanValues] = [ScanValues.init(min: 65, max: 90, inc: 2, wall: "Front"), ScanValues.init(min: 157, max: 180, inc: 2, wall: "Right")]
    
    //labels for counter
    @IBOutlet weak var labelFrontModulo: UILabel!
    @IBOutlet weak var labelCounter: UILabel!
    @IBOutlet weak var labelDistanceFront: UILabel!
    @IBOutlet weak var labelPingDistance: UILabel!
    @IBOutlet weak var labelServoAngle: UILabel!
    
    //floorplan container
    @IBOutlet weak var containerFloorPlan: UIView!
    
    //labels for size output
    @IBOutlet weak var labelLengthA: UILabel!
    @IBOutlet weak var labelLengthB: UILabel!
    @IBOutlet weak var labelLengthC: UILabel!
    @IBOutlet weak var labelLengthD: UILabel!
    @IBOutlet weak var labelAreaSize: UILabel!
    
    
    /**
     * Updates Counter. Is called every Second.
     **/
    func updateCounter() {
        counter++
        counterMod = counter % 4
        counterSingle++
        labelCounter.text = String(counter)
        labelFrontModulo.text = String(counterMod)
    }
    
    /**
     * Initialise Labels
     **/
    func initValues(){
        labelPingDistance.text = "0"
        labelServoAngle.text = "90"
        labelCounter.text = "0"
        labelFrontModulo.text = "0"
        labelDistanceFront.text = "0"
    }
    
    func initWallValues(){
        var i: Int = 0
        for wall in walls{
            print("Das hier ist gerade dran: " + String(i))
            
            self.walls[i].points = self.calcWallPoints(i)
            i++;
        }
        
        self.drawFloorPlan()
        self.calcArea()
    }
    
    /**
     * When view did load:
     * - initialise Labels
     * - Create connection
     * - Setup Last Scan Data
     **/
    override func viewDidLoad() {
        super.viewDidLoad();
        
        self.initValues()
        self.createConnection()
        self.getLastData()
        //only for testing
        //self.initWallValues()
    }
    
    /**
     * Looks for connections in BotConnectionManager
     * Creates BotController and BotNavigator for the connection and calls connect() on BotConnectionManager
     **/
    func createConnection(){
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
                }
                bcm.connect(connection);
            }
        }
    }
    
    override func viewDidAppear(animated: Bool){}
    
    /**
     * Reset Function
     * - Reset Wall Array / Index
     * - Reset Floorplan
     * - Reset Bot Position
     **/
    func reset(){

        self.walls = Array()
        self.whichWall = 0
        
        self.clearFloorPlan()
        
        self.bc?.resetPosition({ () -> Void in
            self.logger.log(.Info, data: "Reset Robo Position");
        });
    }
    
    
    @IBAction func startMeasure(sender: AnyObject) {
        self.startAction()
    }
    
    @IBAction func stopMeasure(sender: AnyObject) {
        self.stopAction()
        self.reset()
        self.resetLastDataAction()
    }
    
    /**
     * Start Function
     * Bot starts only if last measure is finished
     * - Calls Reset Function
     * - Starts Timer Counter
     * - Starts Bot Moving
     **/
    func startAction(){

        if(finished == true){
            finished = false
            logger.log(.Info, data: "Start Action Raumvermesser");
            
            self.reset()
  
            self.timerCounter = NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector: Selector("updateCounter"), userInfo: nil, repeats: true)
            
            self.driveAndDetectWalls()
        }else{
            Toaster.show("Scan isn't finished")
        }
    }
    
    /**
     * Stop Function
     * - Stops Bot Scanning
     * - Stops Bot Moving
     * - Stops Counter
     **/
    func stopAction(){
        self.bc?.stopRangeScan({});
        self.bc?.stop({})
        self.timerCounter.invalidate()
        self.timerDrive.invalidate()
        self.timerScanRight.invalidate()
        self.timerScanFront.invalidate()
        
        self.counter = 0
        self.counterMod = 0
        self.labelCounter.text = String(counter)
        self.labelFrontModulo.text = String(counter)
        
        self.finished = true
    }
    
    /**
     * Function is first called in StartAction
     * If detected walls is < 4
     * - Bot starts moving
     * - Bot starts scanning
     * 
     * If detecting walls >= 4 -> All Walls have been detected
     * - Bot stops moving
     * - Draw Floorplan of detected Walls
     * - Calculate Room Area 
     * - Save Wall Data in intern Database
     **/
    func driveAndDetectWalls(){

        //is needed for calculating the single wall length
        self.counterSingle = 0
        
        if(self.whichWall < 4){
            
            self.driveAction()
            self.timerScanFront = NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector: Selector("checkFront"), userInfo: nil, repeats: false)
            
        }else{
            //measure is finished
            self.finished = true
            self.stopAction()
            self.drawFloorPlan()
            self.calcArea()
            self.saveLastData()
        }
    }
    
    /*********** Scan the Front ********************
     * - Function is repeated every second (0.9 second)
     * - Shows the ping distance
     * - if the ping distance is between 3 and 15 -> a Wall is detected
     * - New Wall needs to be added to Wall Array
     * - Stop Bot and turn Bot 90° to the left
     * - Restart Moving Bot and Scan Function
     **/
    
    let mainQueue = dispatch_get_main_queue()
    let taskGroup = dispatch_group_create()
    
    func checkFront(){
        print("checkFront()");
        
        var tempWall: Wall = Wall()
        
        self.bc?.scanRange(45, max: 120, inc: 2, callback: { data in
            
            self.labelDistanceFront.text = String(data.pingDistance)
            self.labelServoAngle.text = String(data.servoAngle)
            
            if(data.pingDistance <= 15 && data.pingDistance > 3 && data.servoAngle <= 80 && data.servoAngle >= 45){
                
                //async
                dispatch_group_async(self.taskGroup, self.mainQueue, {[weak self] in
                    
                    self!.labelPingDistance.text = String(data.pingDistance)
                    
                    //calcwalllength-function needs to be called first!
                    tempWall.length = self!.calcWallLength()
                    
                    self!.stopTimerScan()
                    self!.stopRangeScan()
                    self!.bc?.stop({})
                    tempWall.item = self!.whichWall
                    tempWall.ping = data.pingDistance
                    self!.pingDistance = Float(data.pingDistance)
                    
                    self!.newWall(tempWall, i: self!.whichWall)
                    
                    self!.turnLeft()
                    self!.driveAction()
                    
                }); //close dispatch_group_async
                
                
                // Check if detected walls are under 4 (a rect)
                if(self.whichWall < 4){
                    
                    //async
                    dispatch_group_async(self.taskGroup, self.mainQueue, {[weak self] in
                        self!.timerDrive = NSTimer.scheduledTimerWithTimeInterval(12, target:self!, selector: Selector("driveAndDetectWalls"),
                            userInfo: nil, repeats: false)
                        
                    }); //close dispatch_group_async
                }
                
            }
        });
    }
    
    /**
     * Turns Bot 90° to the left
     * Is called in checkFront
     **/
    func turnLeft(){

        if let bn = bn {
            bn.turnToAngle(Float(90), speed: Float(15), completion: { [weak self] data in
                self!.bc?.resetPosition({[weak self] data in  });
            });
        }
        
    }
    
    /**
     * Starts Bot Moving
     **/
    func driveAction(){
        self.bc?.move(self.velocity, omega: 0, completion: nil);
    }
    
    /**
     * Stops Bot Scanning
     **/
    func stopRangeScan(){
        self.bc?.stopRangeScan({ [weak self] in
            self?.logger.log(.Info, data: "scan stopped")
        });
    }
    
    /**
     * Stops Timer and Reset
     **/
    func stopTimerScan(){
        self.timerScanRight.invalidate()
        self.timerDrive.invalidate()
        self.timerScanFront.invalidate()
        self.counterSingle = 0
    }
    
    /**
     * Add New Wall to Wall-Array
     * - and Calculate Wall Points
     **/
    func newWall(wall: Wall, i: Int){
        
        if(self.whichWall < 4){
            
            self.walls.append(wall)
            self.walls[i].points = self.calcWallPoints(i)
            
            //outputs
            print("Wall Updated!")
            print("Wall Number: " + String(self.walls[i].item))
            print("Distance: " + String(self.walls[i].ping))
            print("Wall Length: " + String(self.walls[i].length))
            
            //count walls size
            self.whichWall++
        }
    }
    
    /**
     * Calculates Wall Length, with Bot velocity and driven time
     **/
    func calcWallLength()-> Float{
        let length: Float = ( self.velocity * Float(self.counterSingle) )
        /*@todo add pingdistance */
        //let length: Float = ( self.velocity * Float(self.counterSingle) ) + self.pingDistance
        return length
    }
    
    /**
     * Clears Floorplan. Complete Container is removed.
     **/
    func clearFloorPlan(){
        while let subview = containerFloorPlan.subviews.last {
            subview.removeFromSuperview()
        }
        
        //containerFloorPlan.backgroundColor = UIColor.whiteColor();
    }
    
    /**
     * Draws Floorplan
     **/
    func drawFloorPlan(){
        print("drawFloorPlan: Start" )
        let imageSize = CGSize(width: self.containerWidth, height: self.containerHeight)
        
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: imageSize))
        let image = self.drawCustomImage(imageSize)
        imageView.image = image
        
        self.containerFloorPlan.addSubview(imageView)
        
    }
    
    /**
     * Setup Context (White Stroke, Size of Context)
     * Starts Drawing Lines at (0,0) -> plus padding
     * For each Wall a Line is drawn
     **/
    func drawCustomImage(oSize: CGSize) -> UIImage {
       
        // Setup our context
        //let bounds = CGRect(origin: CGPoint.zero, size: oSize)
        //let size = CGSizeApplyAffineTransform(oSize, CGAffineTransformMakeScale(0.1, 0.1))
        let opaque = false
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(oSize, opaque, scale)
        let context = UIGraphicsGetCurrentContext()
        
        //let rect = AVMakeRectWithAspectRatioInsideRect(oSize, bounds)
        
        // Setup complete, do drawing here
        CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().CGColor)
        CGContextSetLineWidth(context, 2.0)
        CGContextBeginPath(context)
        
        let padding: CGFloat = 30
        
        let scaleFactor: CGFloat = getScaleFactor(CGFloat(self.walls[0].length), oHeight: CGFloat(self.walls[1].length), padding: padding * 2)
        
        //is needed to center the floorplan in the container
        var paddingX: CGFloat = padding
        var paddingY: CGFloat = padding
        
        //if the size of the width is smaller as the height, then change the x-padding (to center floorplan)
        if self.walls[0].length <= self.walls[1].length {
            paddingX = ( (oSize.width - ( CGFloat(self.walls[0].length) * scaleFactor )) / 2 )
        }else{ // if the size of the height is smaller as the height, then change the y-padding (to center floorplan)
            paddingY = ( (oSize.height - ( CGFloat(self.walls[1].length) * scaleFactor )) / 2 )
        }
        
        //first point starts at (0,0) + padding
        CGContextMoveToPoint(context, paddingX, paddingY)
        
        print("oWidth: \(oSize.width) iWidth: \( CGFloat(self.walls[0].length) * scaleFactor ) paddingX: \(paddingX)")
        print("oHeight: \(oSize.height) iHeight: \( CGFloat(self.walls[1].length) * scaleFactor ) paddingY: \(paddingY)")
        
        //iterate over all walls
        for var i = 0; i < self.walls.count; ++i {
            
            //draw line with second wall-point
            CGContextAddLineToPoint(context, (CGFloat(self.walls[i].points[1].x) * scaleFactor + paddingX), (CGFloat(self.walls[i].points[1].y) * scaleFactor + paddingY) )
            
            print("drawCustomImage: X:"+String(self.walls[i].points[1].x) + " Y: " + String(self.walls[i].points[1].y) )
        }
        
        CGContextStrokePath(context)
    
        // Drawing complete, retrieve the finished image and cleanup
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    /** Scale Function **
     * is needed to scale the floorplan in the container
     * Padding for container can be set
     **/
    func getScaleFactor(oWidth: CGFloat, oHeight: CGFloat, padding: CGFloat) -> CGFloat {
        var scaleFactor: CGFloat = (self.containerWidth - padding) / oWidth;
        
        let newHeight: CGFloat = oHeight * scaleFactor;
        //var newWidth: CGFloat = oWidth * scaleFactor;
        
        if newHeight > (self.containerHeight - padding) {
            scaleFactor = (self.containerHeight - padding) / oHeight
            //newHeight = oHeight * scaleFactor
            //newWidth = oWidth * scaleFactor
        }
    
        return scaleFactor;
    }
    
    /**
     * Calculates Room Area
     * Area is calculated with the formula of a rectangle (A = a * b)
     * In a Rectangle a = c and b = d
     **/
    func calcArea() -> Float{
        var areaSize: Float = 0
        
        if(self.walls.count == 4){
            areaSize = self.walls[0].length * self.walls[1].length
            let areaSizeToMeter: Float = areaSize * 0.0001
            self.labelAreaSize.text = String(areaSizeToMeter) + " m2"
        }
        
        return areaSize;
    }
    
    
    /**
     * Calculates the Points of a Wall
     * if the wall is the first wall
     * - the first Point is (0,0)
     * - the second Point is (wall length, 0)
     * if the all is not the first wall
     * - the first Point is the second Point of the last Wall
     * - the second Point depends on which wall is detected (2,3 or 4)
     **/
    func  calcWallPoints(wallIndex: Int) -> [(x: Float, y: Float)]{
        
        let length: Float = self.walls[wallIndex].length
        let lengthToMeter = length * 0.01
        let lengthToMeterString: String = String(lengthToMeter)
        var points: [(x: Float, y: Float)] = Array()
        
        //first wall
        if(wallIndex == 0){

            //starting point is (0,0)
            points.append((x: 0, y: 0))
            
            //second point is wall length
            points.append((x: length, y: 0))
            self.labelLengthA.text = lengthToMeterString + " m"
            
        }// next wall
        else{
            
            //start point is second point from foreign wall
            points.append((x: self.walls[wallIndex-1].points[1].x, y: self.walls[wallIndex-1].points[1].y))
            
            var newX: Float = self.walls[wallIndex-1].points[1].x
            var newY: Float = self.walls[wallIndex-1].points[1].y
            
            // Second Wall
            if(wallIndex == 1){
                newY = newY + length
                self.labelLengthB.text = lengthToMeterString + " m"
                
            } // Third Wall
            else if(wallIndex == 2){
                //this must be called if the measure would be exact: newX = newX - length
                //we take the value of a (because in a rect: a = c)
                newX = newX - self.walls[0].length
                self.labelLengthC.text = labelLengthA.text! + " (real: " + lengthToMeterString + " m)"
                
            } //Fourth Wall
            else if(wallIndex == 3){
                //this must be called if the measure would be exact: newY = newY - length
                //we take the value of a (because in a rect: b = d)
                newY = newY - self.walls[1].length
                self.labelLengthD.text = labelLengthB.text! + " (real: " + lengthToMeterString + " m)"
                
            }
 
            //add point
            points.append((x: newX, y: newY))
            
        }
        
        return points;
        
    }
    
    /**
     * Saves wall lengths in intern database
     * - but first, save wall array size in database. to know how long to iterate over wall lengths
     **/
    func saveLastData(){
        
        self.prefs.setInteger(walls.count, forKey: "wallSize")
        
        //iterate over walls and save wall length in database
        for wall in self.walls{
            self.prefs.setFloat(wall.length, forKey: "wallLength" + String(wall.item))
        }
        
        self.prefs.synchronize()
    }
    
    /**
     * Get last scan data from intern database
     * - first, check if data does exists in database
     * - then iterate over wall-array size
     * - create for each wall length a new wall and add it to the wall array
     * - show Floorplan and area of database data
     **/
    func getLastData(){
        
        if let wallSize: Int = NSUserDefaults.standardUserDefaults().integerForKey("wallSize") {
            if(wallSize != 0){
                print("Previous WallSize: \(wallSize)")
            
                for (var i = 0; i < wallSize; i++){
                    print("Das hier ist gerade dran: " + String(i))
                    let length: Float = self.prefs.floatForKey("wallLength" + String(i))

                    var newWall: Wall = Wall()
                    newWall.length = length
                    self.walls.append(newWall)
                    self.walls[walls.count - 1].points = self.calcWallPoints(walls.count - 1)
                    
                }
     
                self.drawFloorPlan()
                self.calcArea()
            }
        }

    }
    
    /**
     * Reset data from intern database
     **/
    func resetLastDataAction(){
        NSUserDefaults.standardUserDefaults().removeObjectForKey("wallSize")
        self.labelLengthA.text = "0"
        self.labelLengthB.text = "0"
        self.labelLengthC.text = "0"
        self.labelLengthD.text = "0"
        self.labelAreaSize.text = "0"
        
    }
    
}