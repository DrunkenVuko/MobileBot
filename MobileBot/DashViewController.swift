//
//  DashViewController.swift
//  MobileBot
//
//  Created by Master on 19.11.15.
//  Copyright © 2015 Goran Vukovic. All rights reserved.
//

import UIKit

class DashViewController: UIViewController {
    
    let logger = StreamableLogger();
    let baby = BabysitterBot()
    override func viewDidLoad() {
        super.viewDidLoad();

    }
    
/*   @IBAction func BabyPressed(sender: UIButton) {
        self.logger.log(.Info, data: "Started Babysitter");
        baby.startAction();
    }*/
    
}
