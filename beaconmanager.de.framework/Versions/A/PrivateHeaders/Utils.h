//
//  Utils.h
//  beaconmanager.de
//
//  Created by pape on 09.05.14.
//  Copyright (c) 2014 1000eyes GmbH. All rights reserved.
//  Strictly Confidential
//

#import <Foundation/Foundation.h>

@interface Utils : NSObject

+ (NSString *)getDocumentPath:(NSString*)filename;

+ (NSString *)applicationDocumentsDirectory;
    
+ (BOOL)isIpad;

+ (BOOL)isRetina;

+ (BOOL)isSmallScreen;

+ (NSString*)getDeviceVersion;

+ (NSData*)hexStringToData:(NSString*)hexString;

+ (NSBundle *)getResBundle;

+ (void)postNotificationOnMainThread:(NSString*)notification withDelegate:(id)delegate andObject:(id)object;

+ (NSData*)zipData:(NSData*)data;

+ (NSString *)createURL:(NSString*)requestURL;

@end
