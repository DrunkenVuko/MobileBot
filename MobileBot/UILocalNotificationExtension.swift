//
//  UILocalNotificationExtension.swift
//  iRobot
//
//  Created by leemon20 on 28.06.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

import Foundation

extension UILocalNotification {
    
    convenience init(title: String, body: String, fireDate date: NSDate) {
        self.init();
        
        alertTitle = title;
        alertBody = body;
        fireDate = date;
        
        soundName = UILocalNotificationDefaultSoundName;
        applicationIconBadgeNumber = 0;
    }
}