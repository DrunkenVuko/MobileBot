//
//  Stream.swift
//  iRobot
//
//  Created by leemon20 on 27.06.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

import Foundation

//
//  Observable.swift
//  iRobot
//
//  Created by leemon20 on 27.06.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

import Foundation


class StreamSubscription<T> {
    private weak var stream: Stream<T>?;
    private let onData: Stream<T>.onData;
    
    init(stream: Stream<T>, listener: Stream<T>.onData) {
        self.stream = stream;
        self.onData = listener;
    }
    
    func cancel() {
        stream?.stopListening(self);
    }
}


class Stream<T>{
    typealias onData = (data: T) -> ();
    
    private var subscribers = [StreamSubscription<T>]();
    
    func push(data: T) {
        for subscriber in subscribers {
            subscriber.onData(data: data);
        }
    }
    
    func listen(onData: Stream.onData) -> StreamSubscription<T> {
        let subscriber = StreamSubscription<T>(stream: self, listener: onData);
        
        subscribers.append(subscriber);
        
        return subscriber;
    }
    
    func stopListening(subscriber: StreamSubscription<T>) {
        subscribers = subscribers.filter({ $0 === subscriber });
    }
}