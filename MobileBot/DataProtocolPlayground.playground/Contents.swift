//: Playground - noun: a place where people can play

import Cocoa

class BotConnection {
    var ip: NSString;
    var port: NSNumber;
    
    init() {
        ip = "";
        port = 0;
    }
}

class BotConnectionManager {
    var connections: [BotConnection];
    
    init() {
        connections = [];
    }
}

let defaults = NSUserDefaults.standardUserDefaults();

let bcm = BotConnectionManager();

bcm.connections.append(BotConnection());

defaults.setObject(bcm.connections, forKey: "BotConnections");

defaults.objectForKey("BotConnections");

//class DataProtokolCommandParameter<T> {
//    let name: String;
//    var value: T;
//    
//    init(name: String, value: T) {
//        self.name = name;
//        self.value = value;
//    }
//    
//    func toBytes() -> [UInt8] {
//        return toByteArray(value);
//    }
//    
//    func toByteArray<T>(var value: T) -> [UInt8] {
//        return withUnsafePointer(&value) {
//            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(T)))
//        }
//    }
//}
//
//var digit: Float = 1;
//var mirror = digit.getMirror();
//var type = mirror.valueType;
//
//var param = DataProtokolCommandParameter<Float>(name: "xt", value: 1.4)
//
//param.toBytes()
//
//
//func fromByteArray<T>(value: [UInt8], _: T.Type) -> T {
//    return value.withUnsafeBufferPointer {
//        return UnsafePointer<T>($0.baseAddress).memory
//    }
//}




////: Playground - noun: a place where people can play

//protocol Numeric {}
//
//extension Double : Numeric { }
//extension Float  : Numeric { }
//extension Int    : Numeric { }
//extension Int8   : Numeric { }
//extension Int16  : Numeric { }
//extension Int32  : Numeric { }
//extension Int64  : Numeric { }
//extension UInt   : Numeric { }
//extension UInt8  : Numeric { }
//extension UInt16 : Numeric { }
//extension UInt32 : Numeric { }
//extension UInt64 : Numeric { }
//
//class DataProtokolCommandParameter<T> {
//    let name: String;
//    var value: T?;
//    
//    var description: String {
//        return "DataProtokolCommandParameter -> name: \(name), value: \(value)";
//    }
//    
//    init(name: String, value: T) {
//        self.name = name;
//        self.value = value;
//    }
//    
//    init(name: String, inout bytes: [UInt8]) {
//        self.name = name;
//        self.value = fromByteArray(bytes)
//    }
//    
//    func toBytes() -> [UInt8] {
//        return toByteArray(value);
//    }
//    
//    private func toByteArray<T>(var value: T) -> [UInt8] {
//        return withUnsafePointer(&value) {
//            Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(T)))
//        }
//    }
//    
//    private func fromByteArray<T>(value: [UInt8]) -> T {
//        return value.withUnsafeBufferPointer {
//            return UnsafePointer<T>($0.baseAddress).memory
//        }
//    }
//}
//
//func toByteArray<T>(var value: Any, type: T.Type) -> [UInt8] {
//    return withUnsafePointer(&value) {
//        Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(type)))
//    }
//}
//
//var a: Numeric = 1.0;

func toByteArray<T>(var value: T) -> [UInt8] {
    return withUnsafePointer(&value) {
        Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(T)))
    }
}

func fromByteArray<T>(value: [UInt8], _: T.Type) -> T {
    return value.withUnsafeBufferPointer {
        return UnsafePointer<T>($0.baseAddress).memory
    }
}

// 64 160 00 00
//var testBytes: [UInt8] = [64, 160, 0, 0];
var testBytes: [UInt8] = [0, 0, 160, 64];
fromByteArray(testBytes, Float.self)

//var genericBytes2:[UInt8] = [51, 51, 179, 63];
//var digit: Float = 1;
//var mirror = digit.getMirror();
//var type = mirror.valueType;

//var param = DataProtokolCommandParameter<Float>(name: "xt", value: 1.4)
//var param2 = DataProtokolCommandParameter<Float>(name: "xt", bytes: &genericBytes2)

//// Strings to UInt8 array
//var str = "k";
//var str_bytes = [UInt8](str.utf8);
//
// Float to UInt8 array
//var num: Float = 1.4;
//
//
//var bytes = toByteArray(num)
//
//fromByteArray(bytes, Float.self)
//
//var intTest: Int = 166;
//toByteArray(intTest)
//
//var intBytes: [UInt8] = [148, 45]
//fromByteArray(intBytes, UInt16.self)
//
//var intBytes2: [UInt8] = [45, 148]
//fromByteArray(intBytes2, UInt16.self)

var num = NSNumber(unsignedChar: 21);
num.description

//var anyTest: Any = 166;
//toByteArray(anyTest, UInt16.self)
//
//var anyToInt: Int = anyTest as! Int;
//
//var anyBytes: [UInt8] = [166, 0]
//fromByteArray(anyBytes, UInt16.self)
//
//
//// Seems to be a better approach for converting
//var src: NSNumber = 1.4
//var out: NSNumber = 0;
//
//var data = NSData(bytes: &src, length: sizeof(NSInteger))
//data.getBytes(&out, length: sizeof(NSInteger))
//out
//
//let intBytes2:[UInt8] = [0xA6, 0x00]
//let u16 = UnsafePointer<UInt16>(intBytes2).memory
//println("u16: \(u16)")
//
//let floatBytes2:[UInt8] = [51, 51, 179, 63];
//var float: Float = UnsafePointer<Float>(floatBytes2).memory
//println("u16: \(float)")
//
//var int16: UInt16 = 166;
//var toBytes = NSData(bytes: &int16, length: sizeof(UInt16))
//var x: UInt16 = UnsafePointer<UInt16>(toBytes.bytes).memory
//
//var toFloatBytes = NSData(bytes: &float, length: sizeof(Float))
//var float2: Float = UnsafePointer<Float>(toFloatBytes.bytes).memory



