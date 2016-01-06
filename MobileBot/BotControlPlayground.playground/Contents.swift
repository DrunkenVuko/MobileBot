//: Playground - noun: a place where people can play

import UIKit

let distance: Float = 150;
let distancePassed: Float = 250;

var pred = NSPredicate(format: "distancePassed >= %@", NSNumber(float: distance));

let attrs = NSDictionary(objects: [NSNumber(float: distancePassed)], forKeys: ["distancePassed"]);

pred.evaluateWithObject(attrs);

var num: Float = -15.0;

abs(num) * -1;

enum Direction {
    case Forward, Backward, Left, Right
    
    var description: String {
        switch self {
        case .Forward:
            return "Forward";
        case .Backward:
            return "Backward";
        case .Left:
            return "Left";
        case .Right:
            return "Right";
        default:
            return "Unknown"
        }
    }
}

var dir = Direction.Backward;

dir.description

var toggle = true;

let velocity: Float = 0;
let omega: Float = 0;

let stop = velocity == 0 && omega == 0;

((170.0 + 90.0) % 180.0) % 180.0

let foo:Bool = true;
let dict:[NSObject:AnyObject] = ["":foo];

dict[""] as! NSNumber

let p1 = CGPoint(x: 0.0, y: 0.0);
let p2 = CGPoint(x: 1.0, y: 0.5);
let dist = hypotf(Float(p1.x - p2.x), Float(p1.y - p2.y));

print(dist)

let dest = CGRectMake(p1.x, p1.y, 0, 0);
let destWithInset = CGRectInset(dest, -1.0, -1.0)

-5 > -4

let userInfo:Dictionary<String,Float!> = ["parkingStartX":4,
    "parkingStartY":4,
    "parkingEndX":4,
    "parkingEndY":4]
let parkingStartY = userInfo["parkingStartY"]

let parkingEndY = userInfo["parkingEndY"]
