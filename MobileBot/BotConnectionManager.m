//
//  Der BotConnectionManager verwaltet die Verbindung zum Roboter.
//  iRobot
//
//  Created by master on 17.05.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

#import "BotConnectionManager.h"

@interface BotConnectionManager ()

//@property StreamableLogger *logger;

@end


@implementation BotConnectionManager

// singleton
+(instancetype)sharedInstance
{
    static BotConnectionManager *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[BotConnectionManager alloc] _init];
    });
    
    return _sharedInstance;
}

#pragma mark - Initializers

-(instancetype)_init
{
    if (self = [super init]) {
        _connections = [NSMutableArray new];
//        _logger = [[StreamableLogger alloc] init];
        
        [self loadConnections];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disconnected:) name:@"BotReconnectionRequest" object:nil];
    }
    
    return self;
}

// lädt Verbindungsdaten aus den UserDefaults um sie in der App anzuzeigen
-(void)loadConnections
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSArray *connections = [defaults arrayForKey:@"BotConnections"];
    
    for (NSDictionary *connection in connections) {
        [self connetionWithIp:connection[@"ip"] port:connection[@"port"]];
    }
}

// speichert Verbindungsdaten in der UserDefaults
-(void)saveConnections
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableArray *connections = [NSMutableArray new];
    
    for (BotConnection *connection in self.connections) {
        [connections addObject:@{@"ip": connection.ip, @"port": connection.port}];
    }
    
    [defaults setObject:connections forKey:@"BotConnections"];
    
    [defaults synchronize];
}

// öffnet eine Verbindung über zu einem Roboter mit Angabe einer IP
-(BotConnection * __nonnull)connetionWithIp:(NSString * __nonnull)ip port:(NSNumber * __nonnull)port
{
    for (BotConnection *connection in self.connections) {
        if ([connection.ip isEqualToString:ip] && [connection.port isEqualToNumber:port]) {
            return connection;
        }
    }
    
    BotConnection *connection = [BotConnection connectionWithIp:ip port:port];
    
    [self.connections addObject:connection];
    
    return connection;
}

// öffnet eine Verbindung zu einem Roboter
-(void)connect:(BotConnection *)connection
{
    if (connection.connectionStatus == BotConnectionConnectionStatusDisconnected) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disconnected:) name:@"BotConnectionDisconnected" object:connection];
        
        [connection connect];
    } else {
        // log already connected
    }
}

// trennt eine Verbindung zu einem Roboter
-(void)disconnect:(BotConnection *)connection
{
    if (connection.connectionStatus == BotConnectionConnectionStatusConnected) {
        [connection disconnect];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BotConnectionDisconnected" object:connection];
    } else {
        // log already disconnected
    }
}

// schließt und öffnet eine Verbindung zu einem Roboter
-(void)reconnect:(BotConnection *)connection
{
    [self disconnect:connection];
    [self connect:connection];
}

-(void)disconnected:(NSNotification *)notification
{
    // log disconnected
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self saveConnections];

    NSLog(@"%@", NSStringFromClass([self class]));
}

@end
