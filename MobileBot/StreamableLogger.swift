//
//  CachedLogger.swift
//  iRobot
//
//  Created by leemon20 on 27.06.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

import Foundation



@objc class StreamableLogger : NSObject {
    
    enum LogLevel {
        case Info, Warning, Off

        var description: String {
            get {
                switch self {
                case .Info:
                    return "Info";
                case .Warning:
                    return "Warning";
                case .Off:
                    return "Off";
                default:
                    return "Unknown";
                }
            }
        }
    }
    
    private(set) static var logStream = Stream<String>();
    
    private let dateFormatter: NSDateFormatter;
    
    override init() {
        dateFormatter = NSDateFormatter();
        dateFormatter.locale = NSLocale.currentLocale();
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS";
    }
    
    func log(level: StreamableLogger.LogLevel, data: Any, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        if level != .Off {
            
           let logMsg = "\(dateFormatter.stringFromDate(NSDate())) [\(level.description)] [\(fileName):\(lineNumber)] \(functionName): \(data)";
            //let logMsg = "hello"
//            dispatch_async(dispatch_get_main_queue(), {
            NSLog(logMsg);
                
                StreamableLogger.logStream.push(logMsg);
//            });
        }
    }
    
    func listen(onData: Stream<String>.onData) -> StreamSubscription<String> {
        return StreamableLogger.logStream.listen(onData);
    }
    
    func stopListening(subscriber: StreamSubscription<String>) {
        StreamableLogger.logStream.stopListening(subscriber);
    }
}