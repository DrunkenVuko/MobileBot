//
//  beaconHelper.swift
//  de.beuth-hochschule.mobilebot
//
//  Created by Goran Vukovic on 03.12.15.
//  Copyright © 2015 Goran Vukovic. All rights reserved.
//

import Foundation

class beaconHelper
{
    private var minor: Int = 0
    private var accuracy: Float = 0.0
    private var proximity: Float = 0.0
    
    func updateValues(near: Int, accu: Float, proxi: Float)
    {
        self.accuracy = accu
        self.proximity = proxi
        self.minor = near
    }
    
    func getNear() -> Int
    {
        return self.minor
    }
    
    func getProxy() -> Float
    {
        return self.proximity
    }
    
    func getAccur() -> Float
    {
        return self.accuracy
    }
}