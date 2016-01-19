//
//  DBInfo.h
//  beaconmanager.de
//
//  Created by pape on 01/07/14.
//  Copyright (c) 2014 1000eyes GmbH. All rights reserved.
//  Strictly Confidential
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface DBInfo : NSManagedObject

@property (nonatomic, retain) NSString * apphash;
@property (nonatomic, retain) NSString * dbversion;
@property (nonatomic, retain) NSDate * lastsync;
@property (nonatomic, retain) NSNumber * trackValue;
@property (nonatomic, retain) NSNumber * trial;

@end
