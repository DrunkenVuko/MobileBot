//
//  OfficeHelper.swift
//  MobileBot
//
//  Created by Betty on 05/11/15.
//  Copyright © 2015 Goran Vukovic. All rights reserved.
//

import UIKit

class OfficeHelper: UIViewController {
    
    var bc: BotController?;
    var bn: BotNavigator?;
    let bcm = BotConnectionManager.sharedInstance();
    let logger = StreamableLogger();
    
    
//    Hard coded office coordinates
    var office1: [(CGFloat, CGFloat)] = [(0, 0), (25, 0), (25, 50)]
    
    var office2: [(CGFloat, CGFloat)] = [(0, 0), (-15, 0), (-15, 55)]
    
    var office3: [(CGFloat, CGFloat)] = [(0, 0), (25, 0), (25, 50)]
    
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        createConnection()
        bc?.resetPosition(nil);
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
                goToOffice(office1, completion: nil)
            } else if(sender.tag==2){
                goToOffice(office2, completion: nil)
            } else if(sender.tag==3){
                goToOffice(office3, completion: nil)
            }
            
        } else {
            self.logger.log(.Info, data: "No Bot connection.");
        }

    }
    
    /**
     * Starts iteration for office coordinate list
     **/
    func goToOffice(office: [(CGFloat, CGFloat)], completion: (() -> Void)?){
        // Start iteration
        self.nextSteps(0, coordinates: office, completion: { completion?() })
    }
    
    /**
     * Starts reverse iteration for office coordinate list
     **/
    func goBackFromOffice(office: [(CGFloat, CGFloat)], completion: (() -> Void)?){
        self.reverseSteps(office.count-1, coordinates: office)
    }
    
    /**
     * Calls moveToWithoutObstacle on Bot Navigator by passing coordinate-tuple as a CGPoint
     **/
    func goToCoordinate(coordinate: (CGFloat, CGFloat), completion: (() -> Void)?) {
        
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
            goToCoordinate(coordinates[i], completion: {
                self.nextSteps(i+1, coordinates: coordinates, completion: completion)
            })
        }
    }
    
    /**
     * Same as nextSteps() but in opposite direction in the Array
     * Recursive function that calls goToCoordinate() through an Array of coordinates.
     * After goToCoordinate() for the current coordinate is completed, it calls itself with the index before this one as a parameter
     **/
    func reverseSteps(i: Int, coordinates: [(CGFloat, CGFloat)]){
        if(i < 0){
            
            // Stop if first coordinate (i==0) is reached
            self.logger.log(.Info, data: "reached end.");
            
        } else {
            
            self.logger.log(.Info, data: "step \(i)");
            self.logger.log(.Info, data: "go to [\(coordinates[i])].");
            
            // Go one coordinate back
            goToCoordinate(coordinates[i], completion: {
                self.reverseSteps(i-1, coordinates: coordinates)
            })
            
        }
    }

    
    
}
