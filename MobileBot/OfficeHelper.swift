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
    

    override func viewDidLoad() {
        super.viewDidLoad();
        
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
    
    @IBAction func startClicked(sender: UIButton) {
        
        bc?.resetPosition(nil);
        buero1()
    }
    
    func buero1(){
        var steps = [CGPoint]()
        steps.append(CGPointMake(-50, 0))
        steps.append(CGPointMake(-50, -60))
        steps.append(CGPointMake(0, -60))
        steps.append(CGPointMake(0, 0))
        
        // Start iteration
        self.nextStep(0, coordinates: steps)

    }
    
    func nextStep(i: Int, coordinates: [CGPoint]){
        let length = coordinates.count
        if(i >= length){
            self.logger.log(.Info, data: "reached end.");
        } else {
            self.logger.log(.Info, data: "step \(i)");
            self.logger.log(.Info, data: "go to [\(coordinates[i])].");
            
            goToCoordinate(coordinates[i], completion: {
                self.nextStep(i+1, coordinates: coordinates)
            })
        }
    }
    
    func goToCoordinate(point: CGPoint, completion: (() -> Void)?) {
        
        bn?.moveToWithoutObstacle(point, completion: { data in
            completion?()
        })
    }

    
    
}
