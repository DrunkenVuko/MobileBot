//
//  SecondViewController.swift
//  MobileBot
//
//  Created by Goran Vukovic on 22.10.15.
//  Copyright © 2015 Goran Vukovic. All rights reserved.
//


import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let beaconManager = BeaconManager(hash: "824905c09824e47314f2db7d8e7795f0");
    let logger = StreamableLogger();
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Override point for customization after application launch.
        beaconManager.setDelegate(self);
        beaconManager.start();
        
        logger.log(.Info, data: beaconManager.dbVersion());
        
        // loacal notification permission request
        let types: UIUserNotificationType = [.Badge, .Alert, .Sound];
        let notificationSettings = UIUserNotificationSettings(forTypes: types, categories: nil);
        
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings);
        // loacal notification permission request
        
        UseCaseManager.sharedInstance().run();
        
        print("Anzahl ......." + String(beaconManager.beaconCount))
        
        
        return true
    }

    
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        logger.log(.Info, data: notificationSettings);
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        beaconManager.startBackgroundFetch(completionHandler);
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        logger.log(.Info, data: userInfo.description);
    }
}
