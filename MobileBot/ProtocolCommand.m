//
//  ProtokolCommand.m
//  iRobot
//
//  Created by leemon20 on 16.05.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

#import "ProtocolCommand.h"

@implementation ProtocolCommand

+ (NSArray*)ProtocolCommandKeyMappings
{
    return @[
        @"k",
        @"o",
        @"r",
        @"v",
        @"p",
        @"a",
        @"e",
        @"",
    ];
}

+ (instancetype)withKey:(ProtocolCommandKey)key fields:(NSArray*)fields
{
    return [[self alloc] initWithKey:key fields:fields];
}

+ (instancetype)fromBuffer:(NSData*)buffer
{
    return [[self alloc] initFromBuffer:buffer];
}

- (id)initWithKey:(ProtocolCommandKey)key fields:(NSArray*)fields
{
    if (self = [super init]) {
        _key = key;
        _fields = fields;
    }

    return self;
}

- (id)initFromBuffer:(NSData*)buffer
{
    if (self = [super init]) {
        ProtocolCommandKey key = [self protokolCommandKeyFromBuffer:buffer];

        NSError* error;
        NSArray* pcfs = [self protokolCommandFieldsForProtokolCommandKey:key fromBuffer:buffer error:&error];

        if (error) {
            NSLog(@"%@:%@ :: %@ :: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error.localizedDescription, error.localizedFailureReason);

            _key = ProtocolCommandKeyNone;
        }
        else {
            _key = key;
        }

        _fields = pcfs;
    }

    return self;
}

- (ProtocolCommandKey)protokolCommandKeyFromBuffer:(NSData*)buffer
{
    if (buffer.length > 0) {

        NSString* cmd = [[NSString alloc] initWithBytes:buffer.bytes length:1 encoding:NSUTF8StringEncoding];

        NSLog(@"command key: %@", cmd);

        if (cmd.length > 0) {
            return [self protocolCommandKeyForValue:cmd];
        }
        else {
            return ProtocolCommandKeyNone;
        }
    }

    return ProtocolCommandKeyNone;
}

- (ProtocolCommandKey)protocolCommandKeyForValue:(NSString*)value
{
    NSUInteger key = [ProtocolCommand.ProtocolCommandKeyMappings indexOfObject:value];

    if (key != NSNotFound) {
        return key;
    }
    else {
        return ProtocolCommandKeyNone;
    }
}

- (NSString*)protocolCommandKeyValueForKey:(ProtocolCommandKey)key
{
    return [ProtocolCommand.ProtocolCommandKeyMappings objectAtIndex:key];
}

- (NSArray*)protokolCommandFieldsForProtokolCommandKey:(ProtocolCommandKey)key fromBuffer:(NSData*)buffer error:(NSError**)errorPtr
{
    NSLog(@"%@ -> %lu", NSStringFromSelector(_cmd), (unsigned long)key);

    NSArray* pcfs = @[];
    BOOL errorOccured = NO;

    switch (key) {

    case ProtocolCommandKeyGetForwardKinematics:
        NSLog(@"%@ -> kProtocolCommandKeyGetForwardKinematics", NSStringFromSelector(_cmd));

        if (buffer.length >= 13) {

            ProtocolCommandField* xt = [ProtocolCommandField withName:@"xt" valueFromBuffer:[buffer subdataWithRange:NSMakeRange(1, 4)] valueType:ProtocolCommandFieldTypeFloat];

            ProtocolCommandField* yt = [ProtocolCommandField withName:@"yt" valueFromBuffer:[buffer subdataWithRange:NSMakeRange(5, 4)] valueType:ProtocolCommandFieldTypeFloat];

            ProtocolCommandField* phit = [ProtocolCommandField withName:@"phit" valueFromBuffer:[buffer subdataWithRange:NSMakeRange(9, 4)] valueType:ProtocolCommandFieldTypeFloat];

            pcfs = @[ xt, yt, phit ];
        }
        else {
            errorOccured = YES;
        }

        break;

    case ProtocolCommandKeySetForwardKinematics:
        NSLog(@"%@ -> kProtocolCommandKeySetForwardKinematics", NSStringFromSelector(_cmd));

        break;

    case ProtocolCommandKeyResetBotDynamics:
        NSLog(@"%@ -> kProtocolCommandKeyResetBotDynamics", NSStringFromSelector(_cmd));

        break;

    case ProtocolCommandKeySetBotVelocity:
        NSLog(@"%@ -> kProtocolCommandKeySetBotVelocity", NSStringFromSelector(_cmd));

        break;

    case ProtocolCommandKeyGetPingSensorValue:
        NSLog(@"%@ -> kProtocolCommandKeyGetPingSensorValue", NSStringFromSelector(_cmd));

        if (buffer.length >= 7) {

            ProtocolCommandField* pingDistance = [ProtocolCommandField withName:@"pingDistance" valueFromBuffer:[buffer subdataWithRange:NSMakeRange(1, 4)] valueType:ProtocolCommandFieldTypeFloat];

            ProtocolCommandField* servoAngleGet = [ProtocolCommandField withName:@"servoAngleGet" valueFromBuffer:[buffer subdataWithRange:NSMakeRange(5, 1)] valueType:ProtocolCommandFieldTypeUnsignedChar];

            ProtocolCommandField* servoMotionEnable = [ProtocolCommandField withName:@"servoMotionEnable" valueFromBuffer:[buffer subdataWithRange:NSMakeRange(6, 1)] valueType:ProtocolCommandFieldTypeUnsignedChar];

            pcfs = @[ pingDistance, servoAngleGet, servoMotionEnable ];
        }
        else {
            errorOccured = YES;
        }

        break;

    case ProtocolCommandKeySetServoAngleRange:
        NSLog(@"%@ -> ProtocolCommandKeySetServoAngleRange", NSStringFromSelector(_cmd));

        break;

    case ProtocolCommandKeyGetEncoderPulses:
        NSLog(@"%@ -> kProtocolCommandKeyGetEncoderPulses", NSStringFromSelector(_cmd));

        if (buffer.length >= 9) {

            ProtocolCommandField* numberEncoderPulsesLeft = [ProtocolCommandField withName:@"numberEncoderPulsesLeft" valueFromBuffer:[buffer subdataWithRange:NSMakeRange(1, 4)] valueType:ProtocolCommandFieldTypeLong];

            ProtocolCommandField* numberEncoderPulsesRight = [ProtocolCommandField withName:@"numberEncoderPulsesRight" valueFromBuffer:[buffer subdataWithRange:NSMakeRange(5, 4)] valueType:ProtocolCommandFieldTypeLong];

            pcfs = @[ numberEncoderPulsesLeft, numberEncoderPulsesRight ];
        }
        else {
            errorOccured = YES;
        }

        break;

    case ProtocolCommandKeyNone:
        NSLog(@"%@ -> kProtocolCommandKeyNone", NSStringFromSelector(_cmd));

        break;

    default:
        NSLog(@"%@ -> default", NSStringFromSelector(_cmd));

        break;
    }

    if (errorOccured) {
        if (errorPtr) {
            NSString* description = [NSString stringWithFormat:@"Unable to parse protocol command fields for given protocol command key (%lu).", (unsigned long)key];
            NSString* reason = [NSString stringWithFormat:@"Not enough data inside buffer (%lu).", (unsigned long)buffer.length];

            NSDictionary* userInfo = @{
                NSLocalizedDescriptionKey :
                    NSLocalizedString(description, nil),
                NSLocalizedFailureReasonErrorKey :
                    NSLocalizedString(reason, nil),
                NSLocalizedRecoverySuggestionErrorKey :
                    NSLocalizedString(@"Try running the command again.", nil)
            };

            *errorPtr = [NSError
                errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                           code:401
                       userInfo:userInfo];
        }
    }

    return pcfs;
}

- (NSData*)toByteBuffer
{
    NSMutableData* buffer = [NSMutableData new];

    if (self.key != ProtocolCommandKeyNone) {
        [buffer appendData:[self keyToBuffer]];

        for (ProtocolCommandField* pcf in self.fields) {
            [buffer appendData:[pcf valueToBuffer]];
        }
    }

    return buffer;
}

- (NSData*)keyToBuffer
{
    NSString* value = [self protocolCommandKeyValueForKey:self.key];

    return [value dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"[%@ -> (key: %lu, value: %@), fields: %@]",
                     self.class,
                     (unsigned long)self.key,
                     [self protocolCommandKeyValueForKey:self.key],
                     [self.fields componentsJoinedByString:@","]];
}

- (NSString*)simpleDescription
{
    NSMutableString* desc = [NSMutableString new];

    [desc appendString:@"["];
    [desc appendFormat:@"%@=", [self protocolCommandKeyValueForKey:self.key]];

    for (ProtocolCommandField* pcf in self.fields) {
        [desc appendString:[pcf simpleDescription]];
    }

    [desc appendString:@"]"];

    return desc;
}

@end
