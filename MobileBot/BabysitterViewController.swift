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
import NotificationCenter

/**
 * Diese Klasse dient dem Use Case : Babysitter
 */
class BabysitterViewController: UIViewController {
    
    var timer = NSTimer()

    
    var bc: BotController?;
    var bn: BotNavigator?;
    let bcm = BotConnectionManager.sharedInstance();
    let logger = StreamableLogger();
    let testhardware = TestHardwareController();
    var debounceTimer: NSTimer?
    var notification: UILocalNotification?;
    
    static var enterWhileLeave = false;
    var posStationX = 0,
    posStationY = 0;
    var posDoorLeftX = 101,
    posDoorLeftY = -180,
    posDoorRightX = 10,
    posDoorRightY = -180;
    
    var timerCounter: NSTimer = NSTimer()
    
    var velocity:Float = 10,
    a_velocity:Float = 15,
    stationRight:Float = 181,
    rightLeft:Float = 101,
    leftStation:Float = 206,
    
    a_stationRight:Float = -86,
    a_rightLeft:Float = 86,
    a_leftRight:Float = 180,
    
    t_stationRight:Double = 1.81,
    t_rightLeft:Double = 1.01
    
    
    var alreadyStarted = false;
    
    var someoneAtDoor = false;
    
    
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
//        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "whichBeacon:", userInfo: 0, repeats: true)
    }
        func pushNotification(text: String, titel: String){
        
        /* Create the alert controller */
        let alertController: UIAlertController = UIAlertController(title: titel, message: text, preferredStyle: .Alert)
        
        // Create the actions
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
            UIAlertAction in
            NSLog("OK Pressed")
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {
            UIAlertAction in
            NSLog("Cancel Pressed")
        }
        
        // Add the actions
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        // Present the controller
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    
    @IBOutlet weak var Output: UITextView!
    
    @IBAction func StartBabyPressed(sender: UIButton) {
        startAction()
    }
    
    @IBAction func StopBabyPressed(sender: UIButton) {
        /*bc?.stopRangeScan({ [weak self] in
        self?.logger.log(.Info, data: "scan stopped")
        });
        bc?.stopMovingWithPositionalUpdate({ [weak self] in
        self?.logger.log(.Info, data: "stopped")});*/
        
        
        goToStation();
        
    }
    /**
     * Startet den Use Case
     *
     */
    func startAction() {
        logger.log(.Info, data: "Start Action Babysitter");
        
        if(alreadyStarted == false){
            //reset();
        }
        reset();
        alreadyStarted = true;
        goToDoor();
    }
    
    
    func reset(){
        self.bc?.resetPosition({ () -> Void in
            self.logger.log(.Info, data: "Reset Robo Position");
        });
    }
    
    func goToDoor(){
        self.logger.log(.Info, data: "goToDoor");
        //zuerst zur linkem tuerrand fahren
//        self.bn?.moveToWithoutObstacle(CGPointMake(CGFloat(posDoorRightX), CGFloat(posDoorRightY)), completion: { data in
//            self.logger.log(.Info, data: "baby: MOVE TO doorpoint LEFT finished");
        self.bn?.turnToAngle(self.a_stationRight, speed: self.a_velocity, completion: { data in
            
            self.bc?.move(self.velocity, omega: 0, completion: { data in
            self.logger.log(.Info, data: "baby: MOVE TO doorpoint LEFT finished");
            self.timerCounter = NSTimer.scheduledTimerWithTimeInterval(self.t_stationRight, target:self, selector: Selector("patrol:"), userInfo: false, repeats: false)
            })
        })
            //beginnend von links nach rechts zu patroullieren
            //self.patrol(false);
        //})
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
            //self.Output.text = "scanning room entry \(scandata.pingDistance)";
            self.logger.log(.Info, data: "scanning room entry \(scandata.pingDistance)");
            if (scandata.pingDistance < 40 && scandata.pingDistance > 0) {
                if (scanBugFlag >= 5.0){
                    self.logger.log(.Info, data: "intruder detected");
                    
                    self.someoneAtDoor = true;
                    
                    self.bc?.stopRangeScan({
                        self.bc?.stoptUpdatingPosition();
                        self.bc?.stop({
                            self.goToStation();
                            
                            
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
    
    func patrol(toRight: Bool){
        self.bc?.stop({});
        
        //nur patroullieren wenn kein eindringling in der nähe
        if(someoneAtDoor == false){
            
            
            //var posDoorX = self.posDoorLeftX
            //var posDoorY = self.posDoorLeftY
            var strPos = "Left"
            var toNext = true
            
            var a_pos = self.a_rightLeft
            
            if(toRight){
                //posDoorX = self.posDoorRightX
                //posDoorY = self.posDoorRightY
                strPos = "Right"
                toNext = false
                a_pos = self.a_leftRight
            }
            
            //self.scan();
            
            self.logger.log(.Info, data: "baby: MOVE TO doorpoint "+strPos);
            
            self.bc?.move(Float(self.velocity), omega: 0, completion: { data in
                self.logger.log(.Info, data: "baby: MOVE TO doorpoint LEFT finished");
                self.timerCounter = NSTimer.scheduledTimerWithTimeInterval(self.t_rightLeft, target:self, selector: Selector("patrol:"), userInfo: toNext, repeats: true);
                //self.patrol(toNext)
            })
            
//            self.bn?.moveToWithoutObstacle(CGPointMake(CGFloat(posDoorX), CGFloat(posDoorY)), completion: { data in
//                self.logger.log(.Info, data: "baby: MOVE TO doorpoint "+strPos+" finished");
            
            
           // })
        }
            //hier zurueck an die tuer schicken?
            //oder bei erfolgreichem scan?
        else{
            goToStation()
            
        }
        
    }
    
    func goToStation(){
        
        /*self.bn?.moveToWithoutObstacle(CGPointMake(CGFloat(posStationX), CGFloat(posStationY)), completion: { data in
        self.logger.log(.Info, data: "baby: MOVE TO Station finished");
        self.sendAlarm("Robo at Station");
        })*/
        
        //let data = self.bc?.posData;
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
    
    /*    func pushNotification(){
    
    var AlertView = UIAlertController(title: "You won", message: "Ok", preferredStyle: <#T##UIAlertControllerStyle#>.Alert);
    AlertView.addAction(UIAlertAction(title: "", style: UIAlertActionStyle.Default, handler: nil);
    self.presentedViewController(AlertView, animated:true, completion:nil);
    var Notification = UILocalNotification();
    
    Notification.alertAction = "Okay"
    Notification.alertBody = "Achtung Eindringling"
    Notification.fireDate = NSDate(timeIntervalSinceNow: 5)
    //UIApplication.sharedApplication().scheduledLocalNotifications(Notification)
    
    }*/
    /**
    * Startet den Use Case
    *
    */
    
    /**
    * Schedules a local notification only once by canceling any previously scheduled notification
    */
    func scheduleLocalNotification() {
        /*
        cancelLocalNotification();
        
        let fireDate = NSDate(timeIntervalSinceNow: 5);
        
        notification = UILocalNotification(title: "Unbefugter Eindringling erkannt", body: "Achtung, es wurde ein unbefugter Eindringling erkannt!", fireDate: fireDate);
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification!);
        
        logger.log(.Info, data: "scheduled local notification with fire date: \(fireDate)");
        */
    }
    
    func cancelLocalNotification() {
        /*
        if let notification = notification {
        UIApplication.sharedApplication().cancelLocalNotification(notification);
        
        logger.log(.Info, data: "canceled previously scheduled notification: \(notification)");
        }
        */
    }
    
    // *****
    // http://stackoverflow.com/questions/28411644/search-as-you-type-swift/28412321#28412321
    // *****
    /**
    * Diese Funktion wird aufgerufen, sobald das End-Event vom Beacon gesendet wurde.
    * Dann wird ein Timer von 20 Sekunden gestartet und erst danach wird die startEndAction()
    * aufgerufen. Wird das End-Event öfter gesendet, startet der Timer von 0 und ruft startEndAction()
    * erst auf, wenn die 20 Sekunden durchlaufen wurden.
    */
    func endAction() {
        
        /*
        GuardHouseWhileUserNotHome.enterWhileLeave = false;
        
        if let timer = debounceTimer {
        timer.invalidate()
        }
        
        debounceTimer = NSTimer(timeInterval: 20.0, target: self, selector: Selector("startEndAction"), userInfo: nil, repeats: false)
        
        NSRunLoop.currentRunLoop().addTimer(debounceTimer!, forMode: "NSDefaultRunLoopMode")
        */
    }
    
    /**
     * Diese Funktion beendet den UseCase und führt entsprechende Operationen durch.
     * Sollte während der 20 Wartesekunden ein Start-Event aufgerufen worden sein, so wird im
     * UseCaseManager die Variable enterWhileLeave auf true gesetzt und der Use Case wird nicht beendet.
     *
     */
    func startEndAction(){
        //        if !GuardHouseWhileUserNotHome.enterWhileLeave {
        //
        //            cancelLocalNotification();
        //
        //            UseCaseManager.ghwunhFlag = false;
        //            UseCaseManager.globalEnter=false;
        //
        //            self.bc?.stopRangeScan({ [weak self] in
        //                self?.bn?.moveTo(CGPointMake(CGFloat(0), CGFloat(0)), completion: nil);
        //                })
        //
        //            logger.log(.Info, data: "End GuardHouseWhileUserNotHome!")
        //        }
    }
    
    /*****************************************************************************************************/
     /**************************************** Beacons Cases *********************************************/
     /*****************************************************************************************************/
    
    func test()
    {
        print("::::::::::::::::::::::::::::::::::::::::::::::::::::::::::")
        print("::::::::::::::::::::::::::::::::::::::::::::::::::::::::::")
    }
    
    
     deinit {
        logger.log(.Info, data: "++++++")
    }
}