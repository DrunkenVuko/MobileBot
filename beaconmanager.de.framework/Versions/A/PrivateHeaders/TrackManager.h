//
//  TrackManager.h
//  beaconmanager.de
//
//  Created by pape on 17.06.14.
//  Copyright (c) 2014 1000eyes GmbH. All rights reserved.
//  Strictly Confidential
//

#import <Foundation/Foundation.h>
#import "Beacons.h"
#import "Campaigns.h"

@interface TrackManager : NSObject


/**
 * Initialize the TrackManager
 *
 * @return void
 */
- (id)init;


/**
 * Add a beacon which should be tracked
 *
 * @param Beacons beacon
 *
 * @return void
 */
- (void)addBeacon:(Beacons*)beacon;


/**
 * Add a Campaign which should be tracked
 *
 * @param Campaigns campaign
 * @param BOOL clicked
 *
 * @return void
 */
- (void)addCampaign:(Campaigns*)campaign isClicked:(BOOL)clicked;


/**
 * Syncronize the tracked beacons and campaigns with server
 *
 * @return void
 */
- (void)syncData;

@end
