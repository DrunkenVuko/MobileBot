//
//  ProtocolCommandField.m
//  iRobot
//
//  Created by leemon20 on 17.05.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

#import "ProtocolCommandField.h"

@implementation ProtocolCommandField

+ (instancetype)withName:(NSString*)name
                   value:(NSNumber*)value
               valueType:(ProtocolCommandFieldType)type
{
    return [[self alloc] initWithName:name value:value valueType:type];
}

+ (instancetype)withName:(NSString*)name
         valueFromBuffer:(NSData*)buffer
               valueType:(ProtocolCommandFieldType)type
{
    return [[self alloc] initWithName:name valueFromBuffer:buffer valueType:type];
}

- (instancetype)initWithName:(NSString*)name
                       value:(NSNumber*)value
                   valueType:(ProtocolCommandFieldType)type
{
    if (self = [super init]) {
        _name = name;
        _value = value;
        _type = type;
    }

    return self;
}

- (instancetype)initWithName:(NSString*)name
             valueFromBuffer:(NSData*)buffer
                   valueType:(ProtocolCommandFieldType)type
{
    if (self = [super init]) {
        _name = name;
        _value = [self valueFromBuffer:buffer withType:type];
        _type = type;
    }

    return self;
}

- (NSNumber*)valueFromBuffer:(NSData*)buffer
                    withType:(ProtocolCommandFieldType)type
{
    NSNumber* value;

    switch (type) {
    case ProtocolCommandFieldTypeFloat: {
        NSLog(@"making float from buffer: %@", buffer);

        float num;
        [buffer getBytes:&num length:sizeof(float)];
        value = [NSNumber numberWithFloat:num];
    } break;

    case ProtocolCommandFieldTypeLong: {
        NSLog(@"making long from buffer: %@", buffer);

        int32_t num;
        [buffer getBytes:&num length:sizeof(int32_t)];
        value = [NSNumber numberWithLong:num];
    } break;

    case ProtocolCommandFieldTypeUnsignedChar: {
        NSLog(@"making unsigned char from buffer: %@", buffer);

        uint8_t num;
        [buffer getBytes:&num length:sizeof(uint8_t)];
        value = [NSNumber numberWithUnsignedChar:num];
    } break;

    case ProtocolCommandFieldTypeNone:
        break;

    default:
        break;
    }

    return value;
}

- (NSData*)valueToBuffer
{
    NSMutableData* buffer = [NSMutableData new];

    switch (self.type) {
    case ProtocolCommandFieldTypeFloat: {
        float num = [self.value floatValue];
        [buffer appendBytes:&num length:sizeof(float)];

        NSLog(@"made buffer %@ out of float", buffer);
    } break;

    case ProtocolCommandFieldTypeLong: {
        long num = [self.value longValue];
        [buffer appendBytes:&num length:sizeof(int32_t)];

        NSLog(@"made buffer %@ out of long", buffer);
    } break;

    case ProtocolCommandFieldTypeUnsignedChar: {
        uint8_t num = [self.value unsignedCharValue];
        [buffer appendBytes:&num length:sizeof(uint8_t)];

        NSLog(@"made buffer %@ out of unsigned char", buffer);
    } break;

    case ProtocolCommandFieldTypeNone:
        break;

    default:
        break;
    }

    return buffer;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"[%@, name: %@, value: %@, type: %lu",
                     self.class, self.name, self.value,
                     (unsigned long)self.type];
}

- (NSString*)simpleDescription
{
    return [NSString stringWithFormat:@"[%@=%@,type=%lu]", self.name, self.value,
                     (unsigned long)self.type];
}

@end
