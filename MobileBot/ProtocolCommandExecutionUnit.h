//
//  ProtocolCommandExecutionUnit.h
//  iRobot
//
//  Created by leemon20 on 01.06.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProtocolCommand.h"

typedef void (^PCEUCompletionHandler)(ProtocolCommand* command, NSError* error);

/*!
 * @class ProtocolCommandExecutionUnit
 * @discussion Associates a Command with its completion block.
 */
@interface ProtocolCommandExecutionUnit : NSObject

/*!
 * @discussion Creates a default unit with a command of type none and a completion block that simply logs itself
 * @return ProtocolCommandExecutionUnit
 */
+ (instancetype)defaultUnit;

/*!
 * @discussion Creates a unit with the supplied command and its associated completion handler
 * @param command A Command
 * @param completionHandler A Block that is associated with the supplied command
 * @return ProtocolCommandExecutionUnit
 */
+ (instancetype)executionUnitWithProtocolCommand:(ProtocolCommand*)command
                               completionHandler:(PCEUCompletionHandler)callback;

/*!
 * @discussion A Block that is associated with the command tracked by this instance
 */
@property (nonatomic, copy) PCEUCompletionHandler callback;

/*!
 * @discussion Command that is tracked by this instance
 */
@property ProtocolCommand* executedCommand;

/*!
 * @discussion Initializes self with the supplied command and its associated completion handler
 * @param command A Command
 * @param completionHandler A Block that is associated with the supplied command
 * @return ProtocolCommandExecutionUnit
 */
- (instancetype)initWithProtocolCommand:(ProtocolCommand*)command
                      completionHandler:(PCEUCompletionHandler)callback;

@end
