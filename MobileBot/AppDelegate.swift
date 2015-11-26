//
//  AppDelegate.swift
//  MobileBot
//
//  Created by Goran Vukovic on 22.10.15.
//  Copyright © 2015 Goran Vukovic. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    //let beaconManager = BeaconManager(hash: "824905c09824e47314f2db7d8e7795f0");
    let logger = StreamableLogger();
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Override point for customization after application launch.
        //beaconManager.setDelegate(self);
        //beaconManager.start();
        
        //logger.log(.Info, data: beaconManager.dbVersion());
        
        // loacal notification permission request
        // siehe Code für IOS 7/8 http://www.cakesolutions.net/teamblogs/push-notifications-in-swift-for-ios-7-8
        // Anleitung Zertifikat http://quickblox.com/developers/How_to_create_APNS_certificates
        // http://selise.ch/swift-tutorial-push-notification-dot-net-server/
        // https://www.youtube.com/watch?v=cKV5csbueHA https://www.youtube.com/watch?v=__zMnlsfwj4
        
        //statt
        let types: UIUserNotificationType = [.Badge, .Alert, .Sound];
        let notificationSettings = UIUserNotificationSettings(forTypes: types, categories: nil);
        
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings);
        // loacal notification permission request
        // eventuell : um IOS 7 und IOS 8
        
        
        //UseCaseManager.sharedInstance().run();
        
        return true
    }
    
    
    /*    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
    UIApplication.sharedApplication().registerForRemoteNotifications()
    logger.log(.Info, data: notificationSettings);
    }
    
    func application(application: UIApplication,didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
    //Process the deviceToken and send it to your server
    }
    
    func application(application: UIApplication,didFailToRegisterForRemoteNotificationsWithError error: NSError) {
    //Log an error for debugging purposes, user doesn't need to know
    NSLog("Failed to get token; error: %@", error)
    }*/
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        //beaconManager.startBackgroundFetch(completionHandler);
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        logger.log(.Info, data: userInfo.description);
    }
    
}
