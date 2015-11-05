//
//  ConnectionManager.h
//  beaconmanager.de
//
//  Created by pape on 08.05.14.
//  Copyright (c) 2014 1000eyes GmbH. All rights reserved.
//  Strictly Confidential
//

#import <Foundation/Foundation.h>

@interface ConnectionManager : NSObject {
    id delegate;
}

@property (nonatomic, strong) id delegate;

// Set the Delegate
- (void)setDelegate:(id)appdelegate;

// Perform some Async Request
- (void)executeRequest:(NSString *)requestURL withTimeout:(NSTimeInterval)timeout withPostData:(NSData*)postData callback:(void (^)(NSDictionary*))callback;

// Perform some Sync Request
- (BOOL)executeSyncRequest:(NSString*)requestURL withTimeout:(NSTimeInterval)timeout withPostData:(NSData*)postData;

@end
