//
//  OfficeHelperHome.swift
//  MobileBot
//
//  Created by Betty on 05/11/15.
//  Copyright © 2015 Goran Vukovic. All rights reserved.
//

import UIKit

class OfficeHelperHome: UIViewController, UIPickerViewDataSource,UIPickerViewDelegate {
    
    // Office coordinates
    internal static let OFFICE_1: [(CGFloat, CGFloat)] = [(0, 0), (25, 0), (25, 50)]
    internal static let OFFICE_2: [(CGFloat, CGFloat)] = [(0, 0), (-15, 0), (-15, 55)]
    internal static let OFFICE_3: [(CGFloat, CGFloat)] = [(0, 0), (0, -50), (-50, -50)]
    
    @IBOutlet weak var pickerView: UIPickerView!
    
    var bc: BotController?;
    var bn: BotNavigator?;
    let bcm = BotConnectionManager.sharedInstance();
    let logger = StreamableLogger();
    
    let pickerOptions = ["Buero1", "Buero2", "Buero3"]
    var fromOffice = "Buero1"
    
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        createConnection()
        bc?.resetPosition(nil);
        
        pickerView.delegate = self;
        pickerView.dataSource = self;
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
     * Calls goToOffice(office) depending on the tag of the pressed button
     * Requires BotConnection to be instantiated
     **/
    @IBAction func officeButtonClicked(sender: UIButton){

        if(isConnected()){
            
            if(sender.tag==1){
                goToOffice(OfficeHelperHome.OFFICE_1, completion: {
                    self.goBackFromOffice(OfficeHelperHome.OFFICE_1, completion: nil)
            })
            } else if(sender.tag==2){
                goToOffice(OfficeHelperHome.OFFICE_2, completion: {
                    self.goBackFromOffice(OfficeHelperHome.OFFICE_2, completion: nil)
                })
            } else if(sender.tag==3){
                goToOffice(OfficeHelperHome.OFFICE_3, completion: {
                    self.goBackFromOffice(OfficeHelperHome.OFFICE_3, completion: nil)
                })
            }
            
        } else {
            self.logger.log(.Info, data: "No Bot Connection.");
        }

    }
    
    /**
     * Starts iteration for office coordinate list
     **/
    internal func goToOffice(office: [(CGFloat, CGFloat)], completion: (() -> Void)?){
        // Start iteration
        self.nextSteps(0, coordinates: office, completion: { completion?() })
    }
    
    /**
     * Starts reverse iteration for office coordinate list
     **/
    func goBackFromOffice(office: [(CGFloat, CGFloat)], completion: (() -> Void)?){
        self.reverseSteps(office.count-1, coordinates: office, completion: { completion?() })
    }
    
    /**
     * Calls moveToWithoutObstacle on Bot Navigator by passing coordinate-tuple as a CGPoint
     **/
    internal func goToCoordinate(coordinate: (CGFloat, CGFloat), completion: (() -> Void)?) {
        
        bn?.moveToWithoutObstacle(CGPointMake(coordinate.0, coordinate.1), completion: { data in
            // Execute callback
            completion?()
        })
    }
    
    /**
     * Recursive function that calls goToCoordinate() through an Array of coordinates.
     * After goToCoordinate() for the current coordinate is completed, it calls itself with the next index as a parameter
     **/
    func nextSteps(i: Int, coordinates: [(CGFloat, CGFloat)], completion: () -> Void){
        let length = coordinates.count
        if(i >= length){
            
            // Stop if last coordinate (i==length-1) is reached
            self.logger.log(.Info, data: "reached end.");
            completion()
            
        } else {
            self.logger.log(.Info, data: "step \(i)");
            self.logger.log(.Info, data: "go to [\(coordinates[i])].");
            
            // Go to next coordinate
            self.goToCoordinate(coordinates[i], completion: {
                self.nextSteps(i+1, coordinates: coordinates, completion: completion)
            })
        }
    }
    
    /**
     * Same as nextSteps() but in opposite direction in the Array
     * Recursive function that calls goToCoordinate() through an Array of coordinates.
     * After goToCoordinate() for the current coordinate is completed, it calls itself with the index before this one as a parameter
     **/
    func reverseSteps(i: Int, coordinates: [(CGFloat, CGFloat)], completion: () -> Void){
        if(i < 0){
            
            // Stop if first coordinate (i==0) is reached
            self.logger.log(.Info, data: "reached end.");
            completion()
            
        } else {
            
            self.logger.log(.Info, data: "step \(i)");
            self.logger.log(.Info, data: "go to [\(coordinates[i])].");
            
            // Go one coordinate back
            self.goToCoordinate(coordinates[i], completion: {
                self.reverseSteps(i-1, coordinates: coordinates, completion: completion)
            })
            
        }
    }
    
    /**
     * send 'fromOffice' value from PickerView to OfficeHelperSendRobot
     **/
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "sendRobo") {
            let svc = segue.destinationViewController as! OfficeHelperSendRobot;
            svc.fromOffice = fromOffice
            
        }
    }
    
    //MARK: PickerView Data Source
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerOptions.count
    }
    
    //MARK: PickerView Delegate
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerOptions[row]
    }
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.fromOffice = pickerOptions[row]
    }
    
    
}
