//
//  OfficeHelperSendRobot.swift
//  MobileBot
//
//  Created by Betty on 26/11/15.
//  Copyright © 2015 Goran Vukovic. All rights reserved.
//

import UIKit

class OfficeHelperSendRobot: UIViewController, UIPickerViewDataSource,UIPickerViewDelegate {
    
    let TIMER_INTERVAL = 5.0
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    
    let logger = StreamableLogger()
    let officeHelperHome = OfficeHelperHome()

    var pickerOptions = ["Buero1", "Buero2", "Buero3"]
    
    // Map selectable Strings to office coordinates
    var officeDict = ["Buero1": OfficeHelperHome.OFFICE_1, "Buero2": OfficeHelperHome.OFFICE_2, "Buero3": OfficeHelperHome.OFFICE_3]
    
    var fromOffice: String!
    var toOffice: String!
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        // Remove fromOffice from list of selectable offices
        pickerOptions.removeAtIndex(pickerOptions.indexOf(fromOffice)!)
        
        // Set default for first office
        toOffice = pickerOptions.first!
        
        // Create connection
        officeHelperHome.createConnection()
        
        pickerView.dataSource = self
        pickerView.delegate = self
        
        //titleLabel.text = fromOffice
    }
    
    /**
     * Called on button click
     * Sends roboter to 'fromOffice' and sets timer on TIMER_INTERVALL seconds before calling bringToOffice()
     **/
    @IBAction func pickUpAndBring(sender: AnyObject) {
        self.logger.log(.Info, data: "Fahr von \(fromOffice) zu \(toOffice)");
        
        officeHelperHome.goToOffice(self.officeDict[fromOffice]!, completion: {
            let timer = NSTimer(timeInterval: self.TIMER_INTERVAL, target: self, selector: Selector("bringToOffice"), userInfo: nil, repeats: false)
            NSRunLoop.currentRunLoop().addTimer(timer, forMode: "NSDefaultRunLoopMode")
        })
        
    }
    
    /**
     * Sends roboter back to basis and further to 'toOffice'
     * When at office, sets timer on TIMER_INTERVALL seconds before calling goBackToBasis()
     **/
    func bringToOffice(){
    
        self.logger.log(.Info, data: "Fahr zurück von \(fromOffice)");
        officeHelperHome.goBackFromOffice(self.officeDict[fromOffice]!, completion: {
            
            self.logger.log(.Info, data: "Fahr zu \(self.toOffice)");
            self.officeHelperHome.goToOffice(self.officeDict[self.toOffice]!, completion: {
            
                let timer = NSTimer(timeInterval: self.TIMER_INTERVAL, target: self, selector: Selector("goBackToBasis"), userInfo: nil, repeats: false)
                NSRunLoop.currentRunLoop().addTimer(timer, forMode: "NSDefaultRunLoopMode")
            
            })
        })
    }
    
    /**
     * Sends roboter back to basis from 'toOffice' coordinates
     **/
    func goBackToBasis(){
        self.logger.log(.Info, data: "Fahr zurück von \(toOffice)");
        self.officeHelperHome.goBackFromOffice(self.officeDict[self.toOffice]!, completion: nil)
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
        self.toOffice  = pickerOptions[row]
    }
    
}
