//
//  TrackedCampaign.h
//  beaconmanager.de
//
//  Created by pape on 17.06.14.
//  Copyright (c) 2014 1000eyes GmbH. All rights reserved.
//  Strictly Confidential
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TrackedCampaign : NSManagedObject

@property (nonatomic, retain) NSNumber * cid;
@property (nonatomic, retain) NSNumber * clicked;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * dbversion;

@end
