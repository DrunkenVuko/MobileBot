//
//  ProtokolCommand.h
//  iRobot
//
//  Created by leemon20 on 16.05.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProtocolCommandField.h"

typedef NS_ENUM(NSUInteger, ProtocolCommandKey) {
    ProtocolCommandKeyGetForwardKinematics = 0, // k
    ProtocolCommandKeySetForwardKinematics, // o
    ProtocolCommandKeyResetBotDynamics, // r
    ProtocolCommandKeySetBotVelocity, // v
    ProtocolCommandKeyGetPingSensorValue, // p
    ProtocolCommandKeySetServoAngleRange, // a
    ProtocolCommandKeyGetEncoderPulses, // e
    ProtocolCommandKeyNone // <empty>
};

@interface ProtocolCommand : NSObject

+ (NSArray*)ProtocolCommandKeyMappings;

+ (instancetype)withKey:(ProtocolCommandKey)key fields:(NSArray*)fields;
+ (instancetype)fromBuffer:(NSData*)buffer;

@property ProtocolCommandKey key;
@property NSArray* fields;

- (instancetype)initWithKey:(ProtocolCommandKey)key fields:(NSArray*)fields;
- (instancetype)initFromBuffer:(NSData*)buffer;

- (NSData*)toByteBuffer;
- (NSString*)description;
- (NSString*)simpleDescription;

@end

//Example sending p
//
//bytes received: 8
//raw buffer value: 112 -> p
//
//raw buffer value: 26  ↑ -> Floating Point number, 4 Bytes
//raw buffer value: 97  ↑
//raw buffer value: 33  ↑
//raw buffer value: 66  ↑
//
//raw buffer value: 166   -> Arduino Int: 2 Byte, Long: 4 Byte !!!
//raw buffer value: 0
//
//raw buffer value: 0     -> Bool
//
//command determined: p

//********************* Get Forward Kinematics Values
//Request: <k> (no parameters)
//Reply: <k> “xt” (float, cm), “yt“ (float, cm), “phit” (float, deg)
//
//********************* Set Forward Kinematics Values
//Request: <o> “xt” (float, cm), “yt“ (float, cm), “phit” (float, deg)
//Reply: <o>
//
//********************* Reset Bot Dynamics
//Request: <r> (no parameters)
//Reply: <r>
//
//********************* Set Bot Velocity
//Request: <v>  “botSpeedForward” (float, cm/s), “botSpeedOmega” (float, deg/s)
//Reply: <v>
//
//********************* Get Ping Sensor Value
//Request: <p>
//Reply: <p> “pingDistance” (float, cm, 0:infinit),
//“servoAngleGet” (unsigned char, 0..180 deg, actual angle),
//“servoMotionEnable” (unsigned char)
//
//********************* Set Emergency Stop
//Request: <s> (no parameters)
//Reply: <s>
//
//********************* Set Servo Angle Range
//Request: <a> "servoAngleRangeMin" (unsigned char, 0..180 degrees, default: 1),
//"servoAngleRangeMax" (unsigned char, 0..180 degrees, default: 179),
//"servoAngleRangeInc" (unsigned char, 0..3 deg, default: 2)
//
//Reply: <a>
//
//********************* Get Encoder Pulses
//Request: <e> (no parameters)
//Reply: <e> numberEncoderPulsesLeft (long), numberEncoderPulsesRight (long)
