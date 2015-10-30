//
//  ConnectionClient.m
//  iRobot
//
//  Created by leemon20 on 17.05.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

#import "BotConnection.h"

@interface BotConnection ()

@property (nonatomic, retain) NSInputStream* inputStream;
@property (nonatomic, retain) NSOutputStream* outputStream;


@end

@implementation BotConnection

#pragma mark - Convenient Initializers

+ (instancetype)connectionWithIp:(NSString * __nonnull)ip port:(NSNumber * __nonnull)port
{
    return [[self alloc] initWithIp:ip port:port];
}

#pragma mark - Initializers

- (instancetype)initWithIp:(NSString * __nonnull)ip port:(NSNumber * __nonnull)port
{
    if (self = [super init]) {
        _connectionStatus = BotConnectionConnectionStatusDisconnected;
        _ip = ip;
        _port = port;
    }
    
    return self;
}

#pragma mark - Block based execution

- (void)executeCommand:(ProtocolCommand*)command completion:(void (^)(ProtocolCommand*, NSError*))callback
{
    if (![self isExecutingCommand] && (command.key != ProtocolCommandKeyNone)) {
        self.pceu = [ProtocolCommandExecutionUnit executionUnitWithProtocolCommand:command completionHandler:callback];
        
        NSError* error;
        [self sendCommand:command error:&error];
        
        if (error) {
            self.pceu = nil;
            callback(command, error);
        }
    }
    else {
        NSDictionary* userInfo = @{
                                   NSLocalizedDescriptionKey :
                                       NSLocalizedString(@"Could not execute command.", nil),
                                   NSLocalizedFailureReasonErrorKey :
                                       NSLocalizedString(@"Already executing a command.", nil),
                                   NSLocalizedRecoverySuggestionErrorKey :
                                       NSLocalizedString(@"Wait for any executing command to finish.", nil)
                                   };
        
        NSError* error = [NSError
                          errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                          code:700
                          userInfo:userInfo];
        
        callback(command, error);
    }
}

/*!
 * @discussion Called on command receival from Bot
 * @param command Command received
 */
- (void)commandReceived:(ProtocolCommand*)command
{
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), command.simpleDescription);
    
    if (self.pceu) {
        
        if (self.pceu.executedCommand.key == command.key) {
            self.pceu.callback(command, nil);
        }
        else {
            NSDictionary* userInfo = @{
                                       NSLocalizedDescriptionKey :
                                           NSLocalizedString(@"Could not execute command.", nil),
                                       NSLocalizedFailureReasonErrorKey :
                                           NSLocalizedString(@"Already executing a command.", nil),
                                       NSLocalizedRecoverySuggestionErrorKey :
                                           NSLocalizedString(@"Wait for any executing command to finish.", nil)
                                       };
            
            NSError* error = [NSError
                              errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                              code:700
                              userInfo:userInfo];
            
            self.pceu.callback(self.pceu.executedCommand, error);
        }
        
        self.pceu = nil;
    }
}

- (BOOL)isExecutingCommand
{
    return self.pceu != nil;
}

/*!
 * @discussion Send the supplied command to the bot
 * @param cmd Command to submit
 * @param errorPtr Will be set in case of an error
 * @return Bool
 */
- (BOOL)sendCommand:(ProtocolCommand*)cmd error:(NSError**)errorPtr
{
    if (cmd.key != ProtocolCommandKeyNone) {
        
        NSLog(@"going to send command: %@", cmd.simpleDescription);
        
        NSData* buffer = [cmd toByteBuffer];
        
        [self logBuffer:buffer];
        
        if (self.outputStream != nil && self.connectionStatus == BotConnectionConnectionStatusConnected) {
            [self.outputStream write:[buffer bytes] maxLength:buffer.length];
        }
        else {
            NSLog(@"Not connected!");
            
            if (errorPtr) {
                NSDictionary* userInfo = @{
                                           NSLocalizedDescriptionKey :
                                               NSLocalizedString(@"Operation was unsuccessful.", nil),
                                           NSLocalizedFailureReasonErrorKey :
                                               NSLocalizedString(@"Not connected to any Host.", nil),
                                           NSLocalizedRecoverySuggestionErrorKey :
                                               NSLocalizedString(@"Try connecting first.", nil)
                                           };
                
                *errorPtr = [NSError
                             errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                             code:400
                             userInfo:userInfo];
            }
            
            return false;
        }
    }
    else {
        NSLog(@"%@ : ignoring command", NSStringFromSelector(_cmd));
    }
    
    return true;
}

#pragma mark - Connection Management

- (void)connect
{
    [self disconnect];
    
    NSLog(@"connecting to host: %@, port: %@", self.ip, self.port);
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL,
                                       (__bridge CFStringRef)self.ip,
                                       self.port.intValue,
                                       &readStream,
                                       &writeStream);
    
    self.inputStream = (__bridge NSInputStream*)readStream;
    self.outputStream = (__bridge NSOutputStream*)writeStream;
    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
    [self.outputStream open];
}

/*!
 * @discussion Delegate method of NSStream. Used to send and receive command to and from the bot
 * @param theStream A stream that is connected to the bot
 * @param streamEvent Signals the type of event that is occured
 */
- (void)stream:(NSStream*)theStream handleEvent:(NSStreamEvent)streamEvent
{
    
    NSLog(@"stream event %lu", (unsigned long)streamEvent);
    
    switch (streamEvent) {
            
        case NSStreamEventNone:
            NSLog(@"Stream event none");
            break;
            
        case NSStreamEventOpenCompleted:
            NSLog(@"NSStreamEventOpenCompleted");
            
            [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(connected) userInfo:nil repeats:NO];
            
            break;
            
        case NSStreamEventHasBytesAvailable:
            
            if (theStream == self.inputStream) {
                
                NSMutableData* data = [NSMutableData new];
                uint8_t buffer[1024];
                long len;
                
                while ([self.inputStream hasBytesAvailable]) {
                    len = [self.inputStream read:buffer maxLength:sizeof(buffer)];
                    
                    if (len > 0) {
                        NSLog(@"\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
                        NSLog(@"receiving command");
                        
                        [data appendBytes:(const void*)buffer length:len];
                        
                        [self logBuffer:data];
                        
                        [self commandReceived:[ProtocolCommand fromBuffer:data]];
                    }
                }
            }
            
            break;
            
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"Streamevent has space available");
            
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"NSStreamEventErrorOccurred");
            
            break;
            
        case NSStreamEventEndEncountered:
            NSLog(@"NSStreamEventEndEncountered");
            
            break;
        default:
            NSLog(@"Unknown event");
    }
}

- (void)disconnect
{
    NSLog(@"disconnecting...");
    
    self.connectionStatus = BotConnectionConnectionStatusDisconnected;
    
    if (self.inputStream != nil) {
        NSLog(@"closing: %@", self.inputStream);
        
        self.inputStream.delegate = nil;
        
        [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        [self.inputStream close];
        
        self.inputStream = nil;
    }
    
    if (self.outputStream != nil) {
        NSLog(@"closing: %@", self.outputStream);
        
        self.outputStream.delegate = nil;
        
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        [self.outputStream close];
        
        self.outputStream = nil;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BotConnectionDisconnected" object:self];
}

- (void)connected
{
    self.connectionStatus = BotConnectionConnectionStatusConnected;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BotConnectionConnected" object:self];
}

#pragma mark - Utility

/*!
 * @discussion Logs the contents of the supplied buffer
 * @param buffer Buffer to log
 */
- (void)logBuffer:(NSData*)buffer
{
    //    NSLog(@"buffer byte count: %li ", (unsigned long)buffer.length);
    //    const uint8_t* bytes = [buffer bytes];
    //    for (NSUInteger i = 0; i < buffer.length; ++i) {
    //        NSLog(@"raw bytes: %02u", ((uint8_t*)bytes)[i]);
    //    }
}

#pragma mark - Memory Management

- (void)dealloc
{
    [self disconnect];
    
    NSLog(@"%@:%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

@end
