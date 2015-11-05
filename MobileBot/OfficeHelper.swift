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
        goToCoordinate(CGFloat(100), y: CGFloat(50))
        bc?.stopMovingWithPositionalUpdate(nil)
        bc?.resetPosition({
            self.logger.log(.Info, data: "position reseted");
            });
    }
    
    func goToCoordinate(x: CGFloat, y: CGFloat) {
        
        let point = CGPointMake(x, y)
        
        bn?.moveTo(point, completion: nil)
        
//        bc?.move(y, omega: 0, completion: {
//            self.logger.log(.Info, data: "moved \(y) to the front");
//        });
        
        turnLeft()
        
//        bc?.resetPosition({
//            self.logger.log(.Info, data: "position reseted");
//        });
        
//        bc?.move(x, omega: 0, completion: {
//            self.logger.log(.Info, data: "moved \(x) to the front");
//        });

        
    }
    
    func turnLeft(){
        let degrees: Float = 45;
        if let bn = bn {
            bn.turnToAngle(degrees, speed: 100, completion: { [weak self] data in
                self?.logger.log(.Info, data: "turned left");
                });
        }
    }
    
    func turnRight(){
        let degrees: Float = -45;
        if let bn = bn {
            bn.turnToAngle(degrees, speed: 100, completion: { [weak self] data in
                self?.logger.log(.Info, data: "turned right");
                });
        }
    }
    
    
}
