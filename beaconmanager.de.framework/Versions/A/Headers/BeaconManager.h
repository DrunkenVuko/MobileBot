//
//  BeaconManager.h
//  beaconmanager.de
//
//  Created by pape on 08.05.14.
//  Copyright (c) 2014 1000eyes GmbH. All rights reserved.
//  Strictly Confidential
//

//
//  Framework Version: 1.2
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <SystemConfiguration/SystemConfiguration.h>

@interface BeaconManager : NSObject <CLLocationManagerDelegate, CBPeripheralDelegate, CBCentralManagerDelegate> {
    // Accessable from outside
    NSString *authHash;
    BOOL isActive;
    BOOL showCapabilityAlert;
    NSNumber *beaconCount;
    
    NSMutableDictionary *trackedBeacons;
}

@property (nonatomic, strong) NSString *authHash;
@property (nonatomic) BOOL isActive;
@property (nonatomic) BOOL showCapabilityAlert;
@property (strong, nonatomic) NSNumber *beaconCount;
@property (nonatomic, strong) NSMutableDictionary *trackedBeacons;


#pragma mark - Initialisations

/**
 * Initialize the beaconmanger
 *
 * @return void
 */
- (id)init;


/**
 * Initialize the beaconmanger
 *
 * @param App HashCode
 *
 * @return void
 */
- (id)initWithHash:(NSString*)hashCode;


#pragma mark - Beaconmanager Control

/**
 * Stop the monitor and clears the database
 *
 * @param App HashCode
 *
 * @return void
 */
- (void)logoutWithHash:(NSString*)hashCode;


/**
 * Starts the BeaconManager
 *
 * @return void
 */
- (void)start;


/**
 * Stops the BeaconManager
 *
 * @return void
 */
- (void)stop;


/**
 * Starts the Background Fetch (Update Database)
 *
 * @param Completion Handler
 *
 * @return void
 */
- (void)startBackgroundFetch:(void (^)(UIBackgroundFetchResult))completionHandler;


/**
 * Admin Login
 * thows a Notification with Result Object
 *
 * @param Login: email adress
 * @param Password: password
 *
 * @return void
 */
- (void)adminLogin:(NSString*)login withPassword:(NSString*)password;


#pragma mark - Setter

/**
 * Sets the Delegate
 *
 * @param AppDelegate
 *
 * @return void
 */
- (void)setDelegate:(id)appDelegate;


/**
 * Sets the App Hash
 *
 * @param App Hash
 *
 * @return void
 */
- (void)setHash:(NSString *)hash;


/**
 * If set to enabled the campaigns will be triggered.
 * If not, no campaign will be triggered until it is set to enabled again.
 *
 * @param Boolean: enabled
 *
 * @return void
 */
- (void)triggerCampaigns:(BOOL)enable;


/**
 * If set enabled the beaconmanager will monitor the beacons in background too
 *
 * @param Boolean: enabled
 *
 * @return void
 */
- (void)backgroundMode:(BOOL)enable;


#pragma mark - Getter

/**
 * Returns the current dbVersion
 *
 * @return NSDate: dbVersion as Date
 */
- (NSDate* )dbVersion;


/**
 * Returns the setted App Hash
 *
 * @return NSString: App Hash
 */
- (NSString* )hashCode;


/**
 * Returns the vendorId
 *
 * @return NString: Vendor ID
 */
- (NSString* )vendorId;






@end
