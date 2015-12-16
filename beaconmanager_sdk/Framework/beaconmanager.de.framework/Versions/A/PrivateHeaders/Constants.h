//
//  Constants.h
//  beaconmanager.de
//
//  Created by pape on 08.05.14.
//  Copyright (c) 2014 1000eyes GmbH. All rights reserved.
//  Strictly Confidential
//

#import <Foundation/Foundation.h>

@interface Constants : NSObject

extern NSString* const FrameworkVersion;

// Server Settings

extern NSString* const ProtocolType;
extern NSString* const BaseURL;
extern NSString* const CheckDatabaseURL;
extern NSString* const TrackedItemsURL;
extern NSString* const ScannedItemsURL;
extern NSString* const UpdateDatabaseURL;
extern NSString* const GetAdminURL;
extern NSString* const SSLCRT;


// Database IDS

extern int const DBProyimityImmediate;
extern int const DBProyimityNear;
extern int const DBProyimityFar;


// CONST Values

extern float const DBTrackedBeaconUpdateTime;
extern float const ScanBeaconsTimeIntervall;
extern float const ScanBeaconsRepeatIntervall;

@end
