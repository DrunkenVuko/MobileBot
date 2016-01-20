//
//  DatabaseManager.h
//  beaconmanager.de
//
//  Created by pape on 08.05.14.
//  Copyright (c) 2014 1000eyes GmbH. All rights reserved.
//  Strictly Confidential
//

#import <Foundation/Foundation.h>
#import "ConnectionManager.h"
#import "Beacons.h"
#import "Campaigns.h"
#import <CoreLocation/CoreLocation.h>
#import "DBInfo.h"
#import "ScannedBeacon.h"

@interface DatabaseManager : NSObject {
    id delegate;
}

@property (nonatomic, strong) id delegate;

// Initialize the DatabaseManager with given hash
- (id)init;
// Set the Delegate
- (void)setDelegate:(id)appdelegate;
- (void)checkDBNeedsUpdate:(void (^)(BOOL))callback;
- (BOOL)updateDatabase;

#pragma mark - Setters
- (void)setLastProximity:(Beacons *)beacon andProximity:(int)proximity;
- (void)setLastSeen:(Beacons *)beacon setLost:(BOOL)lost;
- (void)setFirstSeen:(Beacons *)beacon setLost:(BOOL)lost;
- (void)setLastTrigger:(Campaigns *)campaign;
- (void)setTrackedBeacon:(Beacons*)beacon;
- (void)setTrackedCampaign:(Campaigns*)campaign isClicked:(BOOL)clicked;
- (void)setScannedBeacon:(ScannedBeacon*)beacon;

#pragma mark - Getters
- (NSArray *)getBeacons;
- (NSArray *)getGroups;
- (NSArray *)getCampaigns;
- (Beacons *)getBeaconWithBeacon:(CLBeacon *)beacon;
- (NSArray *)getCampaign:(Beacons *)beacon;
- (DBInfo *)getDBInfo;
- (NSArray*)getTrackedBeacons;
- (NSArray*)getTrackedCampaigns;
- (NSArray*)getScannedBeacons;
- (NSArray*)getCampaignsWithRegion:(CLBeaconRegion*)region andTriggerId:(NSNumber*)triggerId;

#pragma mark - Delete
- (void)deleteDBObjects:(NSArray*)objects;

#pragma mark - Clear Database
- (void)clearDatabase;

@end
