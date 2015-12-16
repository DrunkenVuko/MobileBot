//
//  BeaconGroups.h
//  beaconmanager.de
//
//  Created by pape on 23.05.14.
//  Copyright (c) 2014 1000eyes GmbH. All rights reserved.
//  Strictly Confidential
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Beacons, Campaigns;

@interface BeaconGroups : NSManagedObject

@property (nonatomic, retain) NSNumber * bgid;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *campaigns;
@property (nonatomic, retain) NSSet *beacons;
@end

@interface BeaconGroups (CoreDataGeneratedAccessors)

- (void)addCampaignsObject:(Campaigns *)value;
- (void)removeCampaignsObject:(Campaigns *)value;
- (void)addCampaigns:(NSSet *)values;
- (void)removeCampaigns:(NSSet *)values;

- (void)addBeaconsObject:(Beacons *)value;
- (void)removeBeaconsObject:(Beacons *)value;
- (void)addBeacons:(NSSet *)values;
- (void)removeBeacons:(NSSet *)values;

@end
