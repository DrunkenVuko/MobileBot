//
//  Notifications.h
//  beaconmanager.de
//
//  Created by pape on 16.06.14.
//  Copyright (c) 2014 1000eyes GmbH. All rights reserved.
//  Strictly Confidential
//

#import <Foundation/Foundation.h>

@interface Notifications : NSObject

//*** Notification Strings ***//

extern NSString* const DBUpdateSuccessful;
extern NSString* const DBUpdateNotNeccessary;
extern NSString* const DBUpdateStart;
extern NSString* const DBUpdateFinish;
extern NSString* const DBNoDatabase;
extern NSString* const CONStatusPermissionDenied;
extern NSString* const CONStatusAppHashMissing;
extern NSString* const CONStatusNotReachable;
extern NSString* const MONEnterRegion;
extern NSString* const MONExitRegion;
extern NSString* const MONTriggerCampaign;
extern NSString* const CAPCheckSuccesful;
extern NSString* const CAPCheckFailure;
extern NSString* const CustomEvent;
extern NSString* const ADMLoginSuccessful;

@end
