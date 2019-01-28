//
//  LocationManager.swift
//  FLocation
//
//  Created by Ali Fakih on 1/28/19.
//

import Foundation
import UIKit
import CoreLocation
class LocationManager: CLLocationManager {
    var isUpdatingLocation = false
    
    static let shared = LocationManager()
    
    override func startUpdatingLocation() {
        super.startUpdatingLocation()
        
        isUpdatingLocation = true
    }
    
    override func stopUpdatingLocation() {
        super.stopUpdatingLocation()
        
        isUpdatingLocation = false
    }
}
