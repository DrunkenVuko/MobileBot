//
//  Babysitter.swift
//  MobileBot
//
//  Created by Goran Vukovic on 05.11.15.
//  Copyright © 2015 Goran Vukovic. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

/**
 * Diese Klasse dient dem Use Case : Babysitter
 */
class BabysitterViewController: UIViewController, beaconSettingsProtocol {
    
    @IBOutlet weak var beaconNear: UILabel!
    
    /* Kontakt beacons */
    var slBeacon = beaconSettings(proximityUUID: NSUUID(UUIDString: "B8937AE0-DC71-4883-A31B-A0059813159B"))

    var bc: BotController?;
    var bn: BotNavigator?;
    let bcm = BotConnectionManager.sharedInstance();
    let logger = StreamableLogger();
    let testhardware = TestHardwareController();
    var debounceTimer: NSTimer?
    var notification: UILocalNotification?;
    var timer = NSTimer()
    
    static var enterWhileLeave = false;
    var posStationX = 0,
        posStationY = 0;
    var posDoorLeftX = 30,
        posDoorLeftY = 50,
        posDoorRightX = 10,
        posDoorRightY = 50;
    
    var someoneAtDoor = false;
    
    
    override func viewDidLoad() {
        super.viewDidLoad();
        slBeacon.delegate = self

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
    
    @IBOutlet weak var Output: UITextView!
    
    @IBAction func StartBabyPressed(sender: UIButton) {
        startAction()
    }
    
    @IBAction func StopBabyPressed(sender: UIButton) {
        bc?.stopRangeScan({ [weak self] in
            self?.logger.log(.Info, data: "scan stopped")
            });
        bc?.stopMovingWithPositionalUpdate({ [weak self] in
            self?.logger.log(.Info, data: "stopped")});
        
    }
    /**
     * Startet den Use Case
     *
     */
    func startAction() {
        logger.log(.Info, data: "Start Action Babysitter");
        
        reset();
        goToDoor();
        

    }
    
    
    func reset(){
        self.bc?.resetPosition({ () -> Void in
            self.logger.log(.Info, data: "Reset Robo Position");
        });
    
    }
    
    func goToDoor(){
        //zuerst zur linkem tuerrand fahren
        self.bn?.moveToWithoutObstacle(CGPointMake(CGFloat(posDoorLeftX), CGFloat(posDoorLeftY)), completion: { data in
            self.logger.log(.Info, data: "baby: MOVE TO doorpoint LEFT finished");
            
            self.scan();
            //beginnend von links nach rechts zu patroullieren
            self.patrol(false);
        })
    }
  
    //@TODO
    //nochmal ueber die alarmfunktion nachdenken
    func scan() {
        // scanBugFlag = flag welches verhindern soll dass ein Eindringling vom Roboter wahrgenommen wird, wenn keiner vorhanden ist
        // es muss mehrere male hintereinander vom Roboter gesendet werden, dass sich etwas vor ihm befindet
        var scanBugFlag = 0.0;
        
        // scanen des Tuereingans waehrend der patrolAction
        // wenn in einer Distanz kleiner als 30 etwas gescant wird, stoppt der Roboter und senden Alarm + Alarmton
        self.bc?.scanRange(100, max: 150, inc: 3, callback: { scandata in
            self.Output.text = "scanning room entry \(scandata.pingDistance)";
            self.logger.log(.Info, data: "scanning room entry \(scandata.pingDistance)");
            if (scandata.pingDistance < 40 && scandata.pingDistance > 0) {
                if (scanBugFlag >= 5.0){
                    self.logger.log(.Info, data: "intruder detected");
                    
                    self.someoneAtDoor = true;
                    
                    self.bc?.stopRangeScan({
                        self.bc?.stopMovingWithPositionalUpdate({
                            self.logger.log(.Info, data: "stopped cause intruder detected \(scandata.pingDistance)");

                        });
                    });
                    
                    // + Alarm an Eltern abschicken als Toast
                    self.sendAlarm("Alarm!");
                    
                    
                }else{
                    scanBugFlag++;
                }
            }else{
                scanBugFlag = 0.0;
            }
        })
    }
    
    func patrol(toLeft: Bool){
        //nur patroullieren wenn kein eindringling in der nähe
        if(someoneAtDoor == false){
            
            var posDoorX = self.posDoorLeftX
            var posDoorY = self.posDoorLeftY
            var strPos = "Right"
            var toNext = true
        
            if(toLeft){
                posDoorX = self.posDoorRightX
                posDoorY = self.posDoorRightY
                strPos = "Left"
                toNext = false
            }
        
            self.logger.log(.Info, data: "baby: MOVE TO doorpoint "+strPos);
        
            self.bn?.moveToWithoutObstacle(CGPointMake(CGFloat(posDoorX), CGFloat(posDoorY)), completion: { data in
                self.logger.log(.Info, data: "baby: MOVE TO doorpoint "+strPos+" finished");
            
                self.patrol(toNext)
            })
        }
        //hier zurueck an die tuer schicken?
        //oder bei erfolgreichem scan?
        else{
            goToStation()
        
        }
    
    }
    
    func goToStation(){
        
        self.bn?.moveToWithoutObstacle(CGPointMake(CGFloat(posStationX), CGFloat(posStationY)), completion: { data in
            self.logger.log(.Info, data: "baby: MOVE TO Station finished");
            self.sendAlarm("Robo at Station");
        })
        
    }
    
    //Eltern benachrichtigen
    //spaeter mal mit push nachrichten umsetzen
    //@TODO
    func sendAlarm(message: String){
        Toaster.show(message);
    }
    
    /********************** Beacons *************************/
    // MyCoreLocationProtocol delegate
    func didUpateLocation(location: CLLocation) {
        NSLog("VC Did Update Location: \(location)")
    }
    
    // MyBeaconProtocol delegate
    func rangedBeacons(beacons: [AnyObject]) {
        let idx = beacons.endIndex
        let beacon = beacons[idx-1] as! CLBeacon
        beaconNear.text = String(beacon.minor)

        NSLog("Closest beacon: \(beacon.minor)")
    }
    
    func didDetermineState(state: CLRegionState) {
        if (state == .Unknown) {
            NSLog("No more beacon(s)")
        }
    }
    
    deinit {
        logger.log(.Info, data: "++++++");
    }
}