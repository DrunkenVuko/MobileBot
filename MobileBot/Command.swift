//
//  Command.swift
//  iRobot
//
//  Created by leemon20 on 12.06.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

import Foundation

typealias CommandSuccessHandler = ProtocolCommand -> Void;

class Command : CustomStringConvertible {
    var command: ProtocolCommand;
    var predicate: NSPredicate?;
    var onPredicateSatisfiedCommand: Command?;
    var onSuccess: CommandSuccessHandler?;
    
    var description: String {
        get {
            return "\(command) : \(predicate) : \(onPredicateSatisfiedCommand) : \(onSuccess)";
        }
    }
    
    let logger = StreamableLogger();
    
    init(command: ProtocolCommand, predicate: NSPredicate?, onPredicateSatisfiedCommand: Command?, onSuccess: CommandSuccessHandler?) {
        self.command = command;
        self.predicate = predicate;
        self.onPredicateSatisfiedCommand = onPredicateSatisfiedCommand;
        self.onSuccess = onSuccess;
        
        logger.log(.Off, data: "initialized command: \(self)");
    }
    
    convenience init(command: ProtocolCommand) {
        self.init(command: command, predicate: nil, onPredicateSatisfiedCommand: nil, onSuccess: nil);
    }
    
    convenience init(command: ProtocolCommand, predicate: NSPredicate) {
        self.init(command: command, predicate: predicate, onPredicateSatisfiedCommand: nil, onSuccess: nil);
    }
    
    convenience init(command: ProtocolCommand, predicate: NSPredicate, onPredicateSatisfiedCommand: Command) {
        self.init(command: command, predicate: predicate, onPredicateSatisfiedCommand: onPredicateSatisfiedCommand, onSuccess: nil);
    }
    
    convenience init(command: ProtocolCommand, onSuccess: CommandSuccessHandler) {
        self.init(command: command, predicate: nil, onPredicateSatisfiedCommand: nil, onSuccess: onSuccess);
    }
}