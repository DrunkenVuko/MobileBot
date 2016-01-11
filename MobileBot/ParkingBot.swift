//
//  ParkingBot.swift
//  MobileBot
//
//  Created by Betty van Aken on 17.12.15.
//  Copyright © 2015 Goran Vukovic. All rights reserved.
//<

import UIKit

/**
 * Diese Klasse dient dem Use Case : ParkingBot
 */
class ParkingBot: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Street coordinates
    internal static let STREET_POINT_1: (CGFloat, CGFloat) = (0, 0)
    internal static let STREET_POINT_2: (CGFloat, CGFloat) = (100, 0)
    
    @IBOutlet weak var tableView: UITableView!
    
    var bc: BotController?;
    var bn: BotNavigator?;
    let bcm = BotConnectionManager.sharedInstance();
    let logger = StreamableLogger();
    
    var parkingLots: [(Float, Float)] = [(100, 200), (0, 10)]
    var stopped = false
    
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
        
        // listens for PARKINGLOT_END notification
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "insertParkingLot:", name: "PARKINGLOT_END", object: nil)
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
        
        var coordinate = ParkingBot.STREET_POINT_2
        var angle:UInt8 = 0
        
        if(back){
            self.logger.log(.Info, data: "parkingbot: MOVE back");
            coordinate = ParkingBot.STREET_POINT_1
            angle = 180
            
        } else {
            self.logger.log(.Info, data: "parkingbot: MOVE forth");
        }
        
        self.bn?.moveToWithScan(CGPointMake(coordinate.0, coordinate.1), scanAngle: angle, completion: { data in
            self.logger.log(.Info, data: "parkingbot: streetpoint reached.");
            
            // unless stop was called, go to next streetpoint
            if(!self.stopped){
                // resets parkinglots
                self.parkingLots.removeAll()
                
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
        
        self.parkingLots.append((parkingStartX, parkingEndX))
        self.tableView?.reloadData()
    }
    
    /**
     * Starts patroling
     */
    func startAction() {
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
        cell.textLabel?.text = "PARKINGLOT \(indexPath.row+1): \(coordinates.0) -> \(coordinates.1)"
        return cell;
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    }
    // TABLEVIEW DATASOURCE & DELEGATE FUNCTIONS END

}