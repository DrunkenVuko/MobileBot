//
//  CommandQueue.swift
//  iRobot
//
//  Created by leemon20 on 01.06.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

import Foundation

class CommandQueue {
    var queue: [Command] = [];
    let logger = StreamableLogger();
    
    func enqueueCommand(command: Command) {
        queue.insert(command, atIndex: 0);
        
        logger.log(.Off, data: "equeued command: \(command)");
    }
    
    func dequeueCommand() -> Command {
        let command = Command(command: ProtocolCommand(key: ProtocolCommandKey.None, fields: []));
        
        if queue.count > 0 {
            return queue.removeLast();
        }
        
        logger.log(.Off, data: "dequeued command: \(command)");
        
        return command;
    }
    
    func clear() {
        queue = [];
        
        logger.log(.Info, data: "queue cleared");
    }
}