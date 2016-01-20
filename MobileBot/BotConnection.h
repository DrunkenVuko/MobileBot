//
//  BotConnection.h
//  iRobot
//
//  Created by leemon20 on 10.07.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProtocolCommand.h"
#import "ProtocolCommandExecutionUnit.h"

typedef NS_ENUM(NSUInteger, BotConnectionConnectionStatus) {
    BotConnectionConnectionStatusConnected,
    BotConnectionConnectionStatusDisconnected
};

/*!
 * @class BotConnection
 * @discussion Handles a single bot connection. Able to connect, reconnect and disconnect. Can be reused by setting new connection data and reconnecting.
 */
@interface BotConnection : NSObject <NSStreamDelegate>

/*!
 * @discussion Creates a new Instance of BotConnection with the specified ip and port
 * @param ip Bot IP
 * @param port Bot Port
 * @return BotConnection
 */
+ (instancetype)connectionWithIp:(NSString *)ip port:(NSNumber *)port;

/*!
 * @discussion Bot IP
 */
@property NSString *ip;

/*!
 * @discussion Bot Port
 */
@property NSNumber *port;

/*!
 * @discussion Tracks the current command in execution
 */
@property ProtocolCommandExecutionUnit* pceu;

/*!
 * @discussion Connection status of the Bot
 */
@property BotConnectionConnectionStatus connectionStatus;

-(instancetype)init __attribute__((unavailable));

/*!
 * @discussion Initializes self with a bot ip and port
 * @param ip Bot IP
 * @param port Bot Port
 * @return BotConnection
 */
-(instancetype)initWithIp:(NSString *)ip port:(NSNumber *)port;

/*!
 * @discussion Connects to Bot using the ip and port supplied at creation time
 */
- (void)connect;

/*!
 * @discussion Disconnects from a currently connected Bot if any
 */
- (void)disconnect;

/*!
 * @discussion Executes the supplied command. Calls completion block on finish
 * @param command Command to execute
 * @return completion Block to execute on finish
 */
- (void)executeCommand:(ProtocolCommand*)command completion:(PCEUCompletionHandler)callback;

/*!
 * @discussion Determines if a command is currently in execution
 * @return Bool
 */
- (BOOL)isExecutingCommand;

@end
