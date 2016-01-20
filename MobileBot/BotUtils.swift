//
//  BotUtils.swift
//  iRobot
//
//  Created by leemon20 on 13.07.15.
//  Copyright (c) 2015 Beuth Hochschule. All rights reserved.
//

import Foundation
import UIKit

class BotUtils {
    static func distance(from point1: CGPoint, to point2: CGPoint) -> Float {
        return hypotf(Float(point1.x - point2.x), Float(point1.y - point2.y));
    }
}