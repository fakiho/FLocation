//
//  TimeInterval.swift
//  FLocation
//
//  Created by Ali Fakih on 1/28/19.
//

import Foundation
import UIKit
extension TimeInterval {
    func minute() -> Int {
        let time = NSInteger(self)
        _ = Int(self.truncatingRemainder(dividingBy: 1) * 1000)
        _ = time % 60
        let minutes = (time / 60) % 60
        return minutes
    }
}
