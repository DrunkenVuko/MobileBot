//
//  MobileBotTests.swift
//  MobileBotTests
//
//  Created by Goran Vukovic on 22.10.15.
//  Copyright © 2015 Goran Vukovic. All rights reserved.
//

import XCTest
@testable import MobileBot

class MobileBotTests: XCTestCase {
    
    var bc: BotController?
    var bn: BotNavigator?
    var bcm = BotConnectionManager.sharedInstance()
    var defaults = NSUserDefaults.standardUserDefaults()

    
    var ip = "wifibee01"
    var port = 2000
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        var connection: BotConnection?
        
        bcm.connetionWithIp(ip, port: port)
        bcm.reconnect(connection)
        
        defaults.setObject(bcm.connections, forKey: "BotConnections")
        
        defaults.objectForKey("BotConnections")
        
        if bcm.connections.count > 0 {
            connection = bcm.connections[0] as? BotConnection
            
            if let connection = connection {
                connection.ip = ipTextField.text;
                connection.port = (portTextField.text as! NSString).integerValue;
            }
        } else {
            connection =
        }
        
//
//        
//        let connection = BotConnection
//        
//        connections = [];
//        
//
//    
//        let defaults = NSUserDefaults.standardUserDefaults();
//    
//        let bcm = BotConnectionManager();
//    
//        bcm.connections.append(BotConnection());
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testConnect(){
        if let connection = bcm.connections[0] as? BotConnection {
            bc = BotController(connection: connection);
            
            if let bc = bc {
                bn = BotNavigator(controller: bc);
            }
            
            bcm.connect(connection);
        }

    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
