//
//  AdsLog.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//
//  Logger chung cho toàn package — chỉ in ở DEBUG build.
//

import Foundation

enum AdsLog {
    static func debug(_ tag: String, _ message: @autoclosure () -> String) {
#if DEBUG
        print("[\(tag)] \(message())")
#endif
    }
}
