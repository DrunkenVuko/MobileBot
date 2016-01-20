//
//  ScannedBeacon.h
//  beaconmanager.de
//
//  Created by pape on 6/26/14.
//  Copyright (c) 2014 1000eyes GmbH. All rights reserved.
//  Strictly Confidential
//

#import <Foundation/Foundation.h>

@interface ScannedBeacon : NSObject {
    NSDictionary *rawData;
    NSString *uuid;
    NSString *major;
    NSString *minor;
    NSNumber *batteryLevel;
    NSString *powerValue; //used from iOS to measure the accuracy (NOT USED FROM US, but for completion)
    NSString *name;
    NSNumber *txPowerLevel;
}

@property (nonatomic, strong) NSString *uuid;
@property (nonatomic, strong) NSString *major;
@property (nonatomic, strong) NSString *minor;
@property (nonatomic, strong) NSNumber *batteryLevel;
@property (nonatomic, strong) NSString *powerValue;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *txPowerLevel;

- (id)initWithData:(NSDictionary*)data;
- (NSString*)description;

@end
