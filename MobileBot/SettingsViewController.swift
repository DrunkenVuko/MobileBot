//
//  Settings.swift
//  iRobot
//
//  Created by leemon20 on 06.07.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController : UIViewController, UITextFieldDelegate {

    @IBOutlet weak var ipTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var botTypeSwitch: UISwitch!
    
    private let logger = StreamableLogger()
    
    @IBAction func AutoLogIn(sender: AnyObject)
    {
        ipTextField.text = "192.168.43.98"
        //ipTextField.text = "wifibee06"
        portTextField.text = "2000"
    }
    override func viewDidLoad() {
        prepareForDisplay()
        
        ipTextField.delegate = self
        
        botTypeSwitch.addTarget(self, action: "botTypeChanged", forControlEvents: .ValueChanged)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "connected:", name: "BotConnectionConnected", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "disconnected:", name: "BotConnectionDisconnected", object: nil)
    }
    
    func connected(notification: NSNotification?) {
        logger.log(.Info, data: "connected")
        
        Toaster.show("Connection established")
    }
    
    func disconnected(notification: NSNotification?) {
        logger.log(.Info, data: "disconnected")
        
        Toaster.show("Disconnected")
    }
    
    func botTypeChanged() {
        logger.log(.Info, data: botTypeSwitch.on)
        
        var info = [String:Bool]()
        
        info["usingLargeBot"] = self.botTypeSwitch.on
        
        let notification = NSNotification(name: "BotTypeDidChange", object: nil, userInfo: info)
        
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
    func prepareForDisplay() {
        let bcm = BotConnectionManager.sharedInstance()
        
        if bcm.connections.count > 0 {
            let connection = bcm.connections[0] as? BotConnection
            
            if let connection = connection {
                ipTextField.text = connection.ip
                portTextField.text = String(stringInterpolationSegment: connection.port)
            }
        }
    }
    
    @IBAction func save(sender: UIBarButtonItem) {
        logger.log(.Info, data: "saving...")
        
        let bcm = BotConnectionManager.sharedInstance()
        
        if bcm.connections.count > 0 {
            let connection = bcm.connections[0] as? BotConnection
            
            if let connection = connection {
                connection.ip = ipTextField.text
                connection.port = Int(portTextField.text!)
            }
        } else {
            bcm.connetionWithIp(ipTextField.text, port: Int(portTextField.text!))
        }
        
        bcm.saveConnections()
        
        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "BotConnectionDidChange", object: nil))
    }
    
    @IBAction func connect(sender: UIButton) {
        logger.log(.Info, data: "reconnecting...")
        
        let bcm = BotConnectionManager.sharedInstance()
        var connection: BotConnection?
        
        if bcm.connections.count > 0 {
            connection = bcm.connections[0] as? BotConnection
            
            if let connection = connection {
                connection.ip = ipTextField.text
                connection.port = Int(portTextField.text!)
            }
        } else {
            connection = bcm.connetionWithIp(ipTextField.text, port: Int(portTextField.text!))
        }
        
        logger.log(.Info, data: "reconnecting to ip:\(connection?.ip), port:\(connection?.port)")
        
        bcm.reconnect(connection)
        
        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "BotReconnectionRequest", object: nil))
    }
    
    @IBAction func done(sender: UIBarButtonItem) {
        logger.log(.Info, data: "canceling...")
        
        exit()
    }
    
    func exit() {
        logger.log(.Info, data: "exiting...")
        
        self.parentViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        logger.log(.Info, data: "✝ (rip) ✝")
    }
}
