//
//  PersistableRegion.swift
//  iRobot
//
//  Created by leemon20 on 22.05.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

import Foundation
import CoreLocation

class PersistableRegion: CLCircularRegion {
    
    private let RADIUS_KEY     = "radius";
    private let IDENTIFIER_KEY = "identifier";
    private let CENTER_KEY     = "center";
    private let LATITUDE_KEY   = "latitude";
    private let LONGITUDE_KEY  = "longitude";
    
    init(contentsOfFile path: String) {
        
        let rd = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource(path, ofType: "plist")!)!;
        
        let rad  = rd[RADIUS_KEY]     as! CLLocationDistance;
        let id   = rd[IDENTIFIER_KEY] as! String;
        let c    = rd[CENTER_KEY]     as! NSDictionary;
        let lat  = c[LATITUDE_KEY]    as! CLLocationDegrees;
        let long = c[LONGITUDE_KEY]   as! CLLocationDegrees;
        
        let coord = CLLocationCoordinate2DMake(lat, long);
        
        super.init(center: coord, radius: rad, identifier: id);
        
        print("region read: \(self)");
    }
    
    func writeToFile(path: String, atomically: Bool) -> Bool {
        let regionDict = NSMutableDictionary();
        let centerDict = NSMutableDictionary();
        
        regionDict.setValue(NSNumber(double: radius), forKey: RADIUS_KEY);
        regionDict.setValue(identifier, forKey: IDENTIFIER_KEY);
        
        centerDict.setValue(NSNumber(double: center.latitude), forKey: LATITUDE_KEY);
        centerDict.setValue(NSNumber(double: center.longitude), forKey: LONGITUDE_KEY);
        
        regionDict.setValue(centerDict, forKey: CENTER_KEY);
        
        print("writing \(self) to file: \(regionDict)");
        
        return regionDict.writeToFile(NSBundle.mainBundle().pathForResource(path, ofType: "plist")!, atomically: atomically);
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
    }
    
    override init(center: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String) {
        super.init(center: center, radius: radius, identifier: identifier);
    }
}