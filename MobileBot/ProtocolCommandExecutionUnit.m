//
//  ProtocolCommandExecutionUnit.m
//  iRobot
//
//  Created by leemon20 on 01.06.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

#import "ProtocolCommandExecutionUnit.h"

@implementation ProtocolCommandExecutionUnit

+ (instancetype)defaultUnit
{
    return [[self alloc] initWithProtocolCommand:[ProtocolCommand withKey:ProtocolCommandKeyNone fields:@[]]
                               completionHandler:^(ProtocolCommand* command, NSError* error) {
                                   NSLog(@"%@:%@", self, NSStringFromSelector(_cmd));
                               }];
}

+ (instancetype)executionUnitWithProtocolCommand:(ProtocolCommand*)command completionHandler:(PCEUCompletionHandler)callback
{
    return [[self alloc] initWithProtocolCommand:command completionHandler:callback];
}

- (instancetype)initWithProtocolCommand:(ProtocolCommand*)command completionHandler:(PCEUCompletionHandler)callback
{
    if (self = [super init]) {
        _executedCommand = command;
        _callback = callback;
    }

    return self;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"pceu: %@", self.executedCommand];
}

@end
