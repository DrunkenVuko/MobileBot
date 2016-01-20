//
//  Toaster.swift
//  iRobot
//
//  Created by leemon20 on 06.07.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

import Foundation
import UIKit

@objc class Toaster : NSObject {
    
    static func show(message: String) {
        let toast = UIAlertView(title: nil, message: message, delegate: nil, cancelButtonTitle: nil);
        //let toast = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
        toast.show();
        
        
        let duration: UInt64 = 2; // duration in seconds
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW as dispatch_time_t, Int64(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), {
            toast.dismissWithClickedButtonIndex(0, animated: true);
        });
    }
    
    static func showInfo(title: String, message: String) {
        let toast = UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: "OK");

        toast.show();
        
    }
}