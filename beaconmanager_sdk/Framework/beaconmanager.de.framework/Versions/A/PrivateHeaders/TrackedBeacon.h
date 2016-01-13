//
//  TrackedBeacon.h
//  beaconmanager.de
//
//  Created by pape on 17.06.14.
//  Copyright (c) 2014 1000eyes GmbH. All rights reserved.
//  Strictly Confidential
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TrackedBeacon : NSManagedObject

@property (nonatomic, retain) NSNumber * bid;
@property (nonatomic, retain) NSString * major;
@property (nonatomic, retain) NSString * minor;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSDate * date;

@end
