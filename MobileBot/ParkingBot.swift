//
//  ParkingBot.swift
//  MobileBot
//
//  Created by Betty van Aken on 17.12.15.
//  Copyright © 2015 Goran Vukovic. All rights reserved.
//

import UIKit

/**
 * Diese Klasse dient dem Use Case : ParkingBot
 */
class ParkingBot: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let BEACON_OFFICE = "4020"
    let BEACON_HOME = "4010"
    
    // Street coordinates
    let STREET_POINT_1: (Float, Float) = (0, 0)
    var STREET_POINT_2: (Float, Float) = (100, 0)
    let DISTANCE = 100
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var distanceToScanField: UITextField!
    @IBOutlet weak var parkingLotSizeField:UITextField!
    
    var bc: BotController?;
    var bn: BotNavigator?;
    let bcm = BotConnectionManager.sharedInstance();
    let logger = StreamableLogger();
    
    var parkingLots: [(Float, Float)] = []
    var stopped = true
    
    var parkingLotSize: Int32 = 20
    
    var positiondata: (Float, Float, Float) = (0, 0, 0)
    var parkStart: (Float, Float, Float) = (0, 0, 0)
    var inParkingLot = false
    
    var beaconStarted = false
    
    @IBAction func startWithBeaconPressed(sender: AnyObject) {
        if(stopped){
            beaconStarted = true
            self.logger.log(.Info, data: "Start Beacon Notifications");
        }
    }
    
    @IBAction func startPressed(sender: AnyObject) {
        self.startAction()
    }
    
    @IBAction func stopPressed(sender: AnyObject) {
        self.stopAction()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        createConnection()
        bc?.resetPosition(nil);
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        // listens for PARKINGLOT_END notification
        notificationCenter.addObserver(self, selector: "insertParkingLot:", name: "PARKINGLOT_END", object: nil)
        
        // listens for "CustomEvent" (Beacon specific SDK Event) notification
        notificationCenter.addObserver(self, selector: "beaconNotification:", name: CustomEvent, object: nil)

    }
    
    /**
     * Looks for connections in BotConnectionManager
     * Creates BotController and BotNavigator for the connection and calls connect() on BotConnectionManager
     **/
    func createConnection(){
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
    
    /**
     * Checks if BotConnection is initialized and connected
     **/
    func isConnected() -> Bool {
        let connectedStatus: BotConnectionConnectionStatus = .Connected
        return (bc?.connectionStatus == connectedStatus)
    }
    
    /**
     * Sends the roboter from one street point to the other
     * Scans for empty parking lots in between
     */
    func patrol(back: Bool){
        
        var coordinate = self.STREET_POINT_2
        var angle:UInt8 = 0
        
        if(back){
            self.logger.log(.Info, data: "parkingbot: MOVE back");
            coordinate = self.STREET_POINT_1
            angle = 180
            
        } else {
            self.logger.log(.Info, data: "parkingbot: MOVE forth");
        }
        
        self.moveToWithScan(CGPointMake(CGFloat(coordinate.0), CGFloat(coordinate.1)), scanAngle: angle, completion: { data in
            self.logger.log(.Info, data: "parkingbot: streetpoint reached.");
            
            // unless stop was called, go to next streetpoint
            if(!self.stopped){
                // resets parkinglots
                self.parkingLots.removeAll()
                
                self.logger.log(.Info, data: "Parking Lot size: \(self.parkingLots.count)");
                
                self.patrol(!back)
            }
        })
        
    }
    
    /**
     * Gets called when an EMPTYPARKINGLOT_END notification is fired
     * Writes parkinglot information into the UI
     */
    func insertParkingLot(notification:NSNotification){
        let userInfo:Dictionary<String,Float!> = notification.userInfo as! Dictionary<String,Float!>
        
        // Gets starting and end x-coordinate from notification
        let parkingStartX = userInfo["parkingStartX"]!
        let parkingEndX = userInfo["parkingEndX"]!
        
        
        if(abs(parkingStartX-parkingEndX) >= Float(self.parkingLotSize)){
            self.parkingLots.append((parkingStartX, parkingEndX))
            self.logger.log(.Info, data: "Parking Lot size: \(self.parkingLots.count)");
            
            self.tableView?.reloadData()
        }
    }
    
    /**
     * Starts patroling
     */
    func startAction() {
        
        // Check distance input field
        if(self.distanceToScanField.text != ""){
            self.STREET_POINT_2 = ((self.distanceToScanField.text! as NSString).floatValue, 0)
        } else {
            self.distanceToScanField.text = String(self.DISTANCE)
        }
        
        // Check parking lot size input field
        if(self.parkingLotSizeField.text != ""){
            self.parkingLotSize = (self.parkingLotSizeField.text! as NSString).intValue
        } else {
            self.parkingLotSizeField.text = String(self.parkingLotSize)
        }
        
        self.stopped = false
        patrol(false)
    }
    
    /**
     * Makes roboter stop on the next street point
     */
    func stopAction() {
        self.stopped = true
    }
    
    /**
     * Remove notification observer at the end
     */
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // TABLEVIEW DATASOURCE & DELEGATE FUNCTIONS
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.parkingLots.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
        
        let coordinates = self.parkingLots[indexPath.row]
        cell.textLabel?.text = "PARKINGLOT \(indexPath.row+1): \(Int(coordinates.0)) -> \(Int(coordinates.1))"
        return cell;
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    }
    // TABLEVIEW DATASOURCE & DELEGATE FUNCTIONS END

    
    /**
    * Diese Bewegungs-Funktion dient dem ParkingBot Use Case
    **/
    func moveToWithScan(point: CGPoint, scanAngle: UInt8, completion: ((ForwardKinematicsData) -> ())? ) {
        self.bc?.stopRangeScan({
            self.bc?.stopMovingWithPositionalUpdate({
                self.logger.log(.Info, data: "\(point)");
                
                self.bc?.startUpdatingPosition(true, completion: { data in
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
                        self.bn?.turnToAngle(degrees, speed: (self.bn?.speed)!, completion: { data in
                            let startingPoint = CGPointMake(CGFloat(data.x), CGFloat(data.y));
                            var previousDistance = BotUtils.distance(from: startingPoint, to: point);
                            let dest = CGRectMake(point.x, point.y, 0, 0);
                            let destWithInset = CGRectInset(dest, -1.0, -1.0);
                            
                            self.logger.log(.Info, data: "computed destination area: \(destWithInset), from point: \(point)");
                            
                            self.bc?.startMovingWithPositionalUpdate((self.bn?.speed)!, omega: 0, callback: { data in
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
                            
                            self.bc?.scanRange(scanAngle, max: scanAngle, inc: 0, callback: { scandata in
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
        self.bc?.stopMovingWithPositionalUpdate({
            self.bc?.startUpdatingPosition(true, completion: { data in
                self.logger.log(.Info, data: "destination reached: \(CGPointMake(CGFloat(data.x), CGFloat(data.y)))");
                completion?(data);
            });
        });
        
        self.bc?.stopRangeScan({});
        
        if(self.inParkingLot){
            self.logger.log(.Info, data: "EMPTY PARKING SPACE ENDED AT \(self.positiondata)");
            
            NSNotificationCenter.defaultCenter().postNotificationName("PARKINGLOT_END", object: nil, userInfo:
                ["parkingStartX":self.parkStart.0,
                    "parkingStartY":self.parkStart.1,
                    "parkingEndX":self.positiondata.0,
                    "parkingEndY":self.positiondata.1])
        }
    }
    
    /**
     * Gets called when Beacon Event occurs
     */
    func beaconNotification(idh: NSNotification){

        if(beaconStarted){
            let beaconId :NSString = (idh.object as? NSString)!
            
            switch beaconId {
                
            case BEACON_OFFICE:
                logger.log(.Info, data: "BEACON_OFFICE in range. Start UseCase!")
                if(stopped){
                    startAction()
                }
                break
                
            case BEACON_HOME:
                logger.log(.Info, data: "BEACON_HOME in range. Stop UseCase!")
                stopAction()
                beaconStarted = false
                break
                
            default:
                return
                
            }
        }
    }


}