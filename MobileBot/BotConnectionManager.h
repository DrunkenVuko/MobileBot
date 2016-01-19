//
//  ConnectionClient.h
//  iRobot
//
//  Created by master on 17.05.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BotConnection.h"

@interface BotConnectionManager : NSObject

@property NSMutableArray *connections;

+(instancetype)sharedInstance;

-(instancetype)init UNAVAILABLE_ATTRIBUTE;

-(BotConnection *)connetionWithIp:(NSString *)ip port:(NSNumber *)port;
-(void)loadConnections;
-(void)saveConnections;
-(void)connect:(BotConnection *)connection;
-(void)disconnect:(BotConnection *)connection;
-(void)reconnect:(BotConnection *)connection;

@end
