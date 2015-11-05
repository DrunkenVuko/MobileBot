//
//  BeaconScanner.h
//  beaconmanager.de
//
//  Created by pape on 6/26/14.
//  Copyright (c) 2014 1000eyes GmbH. All rights reserved.
//  Strictly Confidential
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ScanManager : NSObject <CBPeripheralDelegate, CBCentralManagerDelegate> {
    NSMutableDictionary* scannedBeacons;
}

@property (nonatomic, strong) NSMutableDictionary* scannedBeacons;

/**
 * Initialize the ScanManager
 *
 * @return void
 */
- (id)init;

/**
 * Starts the Scanner and scan for beacons from jaalee and discover the batterylevel and powervalue from the beacons
 *
 * @return void
 */
- (void)startScanner;

/**
 * Stops the Scanner
 *
 * @return void
 */
- (void)stopScanner;

/**
 * Synronize the scanned beacons with the server
 *
 * @return void
 */
- (void)syncData;

@end
