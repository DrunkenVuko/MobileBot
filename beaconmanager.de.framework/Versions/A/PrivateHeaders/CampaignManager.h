//
//  CampaignManager.h
//  beaconmanager.de
//
//  Created by pape on 26.05.14.
//  Copyright (c) 2014 1000eyes GmbH. All rights reserved.
//  Strictly Confidential
//
#import <UIKit/UIKit.h>
#import "FXBlurView.h"
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface CampaignManager : NSObject {
    id delegate;
}

@property (nonatomic, strong) id delegate;

//Initialize the Campaignmanager with given Hash
- (id)initWithDelegate:(id)appDelegate andHash:(NSString*)hash;

//Check the given beacon if some campaign should be triggered for this beacon
- (void)checkBeacon:(CLBeacon *)beacon;

//Checks if some campaigns should be triggered for the given region and state
- (void)checkCampaignWithState:(CLRegionState)state andRegion:(CLBeaconRegion*)region;

@end

