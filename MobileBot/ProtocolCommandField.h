//
//  ProtocolCommandField.h
//  iRobot
//
//  Created by leemon20 on 17.05.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NSLog(...)

typedef NS_ENUM(NSUInteger, ProtocolCommandFieldType) {
    ProtocolCommandFieldTypeFloat = 0,
    ProtocolCommandFieldTypeUnsignedChar,
    ProtocolCommandFieldTypeLong,
    ProtocolCommandFieldTypeNone
};

/*!
 * @class ProtocolCommandField
 * @discussion Handles a single command field
 */
@interface ProtocolCommandField : NSObject

/*!
 * @discussion Creates a command field with the supplied name and value
 * @param name Command field name
 * @param value Command field value
 * @return ProtocolCommandField
 */
+ (instancetype)withName:(NSString*)name
                   value:(NSNumber*)value
               valueType:(ProtocolCommandFieldType)type;

/*!
 * @discussion Creates a command field with the supplied name and value. Value is parsed from a data buffer
 * @param name Command field name
 * @param buffer Buffer to parse the command field value from
 * @return ProtocolCommandField
 */
+ (instancetype)withName:(NSString*)name
         valueFromBuffer:(NSData*)buffer
               valueType:(ProtocolCommandFieldType)type;

/*!
 * @discussion Command field name
 */
@property (copy) NSString* name;

/*!
 * @discussion Command field value
 */
@property (copy) NSNumber* value;

/*!
 * @discussion Command field value type
 */
@property ProtocolCommandFieldType type;

/*!
 * @discussion Initializes self with the supplied name and value
 * @param name Command field name
 * @param value Command field value
 * @return ProtocolCommandField
 */
- (instancetype)initWithName:(NSString*)name
                       value:(NSNumber*)value
                   valueType:(ProtocolCommandFieldType)type;

/*!
 * @discussion Initializes self with the supplied name and value. Value is parsed from a data buffer
 * @param name Command field name
 * @param buffer Buffer to parse the command field value from
 * @return ProtocolCommandField
 */
- (instancetype)initWithName:(NSString*)name
             valueFromBuffer:(NSData*)buffer
                   valueType:(ProtocolCommandFieldType)type;

/*!
 * @discussion Extracts a command field value form a given buffer by considering its type.
 * @param buffer Buffer to extract the value from
 * @param type Command field value type
 * @return NSNumber
 */
- (NSNumber*)valueFromBuffer:(NSData*)buffer
                    withType:(ProtocolCommandFieldType)type;

/*!
 * @discussion Converts own command field value to a byte representation under consideration of its type
 * @return NSData
 */
- (NSData*)valueToBuffer;

- (NSString*)description;
- (NSString*)simpleDescription;

@end
