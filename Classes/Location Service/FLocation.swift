//
//  FLocation.swift
//  FLocation
//
//  Created by Ali Fakih on 1/28/19.
//

import Foundation
import CoreLocation
import CoreMotion
import UIKit

enum StatusAction: String {
    case General    = "General"
    case Walking = "Walking"
    case Driving = "Driving"
}
enum MonitorKeys: String {
    case fLocation = "firstLocation"
    case fwLocation = "firstWalkingLocation"
    case fdLocartion = "firstDrivingLocation"
    case longestRoute = "LongestRoute"
    
    case TotalKM = "totalKM"
    case TotalHrs = "totalHrs"
    case LongDistance = "longdistance"
    case AVGSpeed = "avgspeed"
    case TopSpeed = "topSpeed"
    case LongHours = "longhours"
    case LocationLongDistance = "distanceLongDistance"
    case LocationLongHrs = "locationLongHrs"
    case SitVisite = "sitevisite"
}
enum LocationAuthKey {
    case InUserAuth, AlwaysAuth, FullAuth
}

@available(iOS 11.0, *)
class FLocation: NSObject {
    typealias DataUpdateCallBack = (_ location: CLLocation,_ tag: String, _ status: String) -> ()
    var dataUpdate: DataUpdateCallBack?

    static let shared = FLocation()
    let motionActivityManager = CMMotionActivityManager()
    var CLocationManager = LocationManager()
    
    private var _CustomLocation: CLLocation!
    private var _startDate: Date!
    private var _traveledDistance: Double = 0
    private var _startLocation: CLLocation!
    private var _lastLocation: CLLocation!
    private var _tempLocarion: CLLocation!
    private var _startDateRegion: Date!
    private let _cal = Calendar.current
    private var _currentSpeed = 0
    private var _speedArray: [Double] = []
    private var _monitoredRegions:[CLCircularRegion] = []
    
    private var _totalDistance = UserDefaults.standard.double(forKey: MonitorKeys.TotalKM.rawValue)
    private var _totalHrs = UserDefaults.standard.double(forKey: MonitorKeys.TotalHrs.rawValue)
    private var _avgSpeed = UserDefaults.standard.double(forKey: MonitorKeys.AVGSpeed.rawValue)
    private var _topSpeed = UserDefaults.standard.double(forKey: MonitorKeys.TopSpeed.rawValue)
    private var _longestHrs = UserDefaults.standard.double(forKey: MonitorKeys.LongHours.rawValue)
    private var _longestDistance = UserDefaults.standard.double(forKey: MonitorKeys.LongDistance.rawValue)
    private var _locationLongHrs = UserDefaults.standard.string(forKey: MonitorKeys.LocationLongHrs.rawValue)
    private var _locationLongDistanceName = UserDefaults.standard.string(forKey: MonitorKeys.LocationLongDistance.rawValue)
    
    
    private func createCustomLoction(latitude:Double = 0, longitude: Double = 0) -> CLLocation {
        let latitudeDouble  = latitude
        let longitudeDouble = longitude
        
        let latitudeDegree  = CLLocationDegrees(exactly: latitudeDouble) ?? 0
        let longitudeDegree = CLLocationDegrees(exactly: longitudeDouble) ?? 0
        
        return CLLocation(latitude: latitudeDegree, longitude: longitudeDegree)
    }
    
    override init() {
        super.init()
        
        self._CustomLocation = createCustomLoction()
        self.CLocationManager = LocationManager()
        self.CLocationManager.showsBackgroundLocationIndicator = true
        self.CLocationManager.delegate = self
        self.CLocationManager.pausesLocationUpdatesAutomatically = false
        self.CLocationManager.allowsBackgroundLocationUpdates = true
        self.CLocationManager.desiredAccuracy =  kCLLocationAccuracyBestForNavigation
        self.CLocationManager.startUpdatingLocation()
        
    }
    
    func requestAuthorization(auth: LocationAuthKey) {
        switch auth {
        case .AlwaysAuth:
            CLocationManager.requestAlwaysAuthorization()
            break
        case .InUserAuth:
            CLocationManager.requestWhenInUseAuthorization()
            break
        case .FullAuth:
            CLocationManager.requestAlwaysAuthorization()
            CLocationManager.requestWhenInUseAuthorization()
        }
    }
    
    func handleLocationAuthStatus(status: CLAuthorizationStatus) -> (CLAuthorizationStatus,String?) {
        switch status {
        case .notDetermined:
            requestAuthorization(auth: LocationAuthKey.FullAuth)
            return(status,"notDetermined")
        case .restricted:
            print("Access denied - likely parental controls are restricting use in this app.")
            return(status,"Access denied - likely parental controls are restricting use in this app.")
        case .denied:
            print("I'm sorry - I can't show location. User has not authorized it")
            return(status,"I'm sorry - I can't show location. User has not authorized it")
        case .authorizedAlways, .authorizedWhenInUse:
            self.CLocationManager.startUpdatingLocation()
            return(status,"Authorized")
        }
    }
}
@available(iOS 11.0, *)
extension FLocation: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        _ = handleLocationAuthStatus(status: status)
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        CLocationManager.startUpdatingLocation()
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        Utils.scheduleLocalNotification(title: "VISIT", subtitle: "Location: \(visit.coordinate) at \(visit.arrivalDate)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Fail with error: \(error.localizedDescription)")
        
        CLocationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Location Exit region")
        CLocationManager.stopMonitoring(for: region)
        CLocationManager.startUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Location Enter a region")
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        
    }
}
@available( iOS 11.0, *)
extension FLocation {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("updating Location Manager")
        let now = Date()
        let state = UIApplication.shared.applicationState
        
        let startDateLocation = now.dateAt(hours: 00, minutes: 00)
        let endDateLocation = now.dateAt(hours: 24, minutes: 00)
        
        if now >= startDateLocation &&
            now <= endDateLocation  {
            
            switch state {
                
            case .active:
                updateLocation(locations: locations)
                
                break
            case .inactive:
                if self._lastLocation == nil && locations.first != nil {self._lastLocation = locations.first}
                createRegion(location: self._lastLocation)
                detectMoving(location: self._lastLocation, locations: locations)
                break
            case .background:
                updateLocation(locations: locations)
                break
            }
        }
    }
    
    func updateLocation(locations: [CLLocation]) {
        print("updating Location")
        if _startLocation == nil { self._startLocation = locations.first }
        if locations.last == nil {
            guard self._lastLocation != locations.first else {return}
            self._lastLocation = locations.first
        }else{
            guard self._lastLocation != locations.last else{return}
            self._lastLocation = locations.last
        }
        
        detectMoving(location: self._lastLocation, locations: locations)
        
    }
    
    func detectMoving(location: CLLocation, locations: [CLLocation]) {
        var status = StatusAction.General.rawValue
        
        /*Emulator Check*/
        #if arch(i386) || arch(x86_64)
        status = StatusAction.Driving.rawValue
        let state = UIApplication.shared.applicationState
        if state == .active {
            dataUpdate?(location, "Foreground", status)

        }else {

            dataUpdate?(location, "Background", status)
        }
        self.setDate()
        self.setAvgSpeed(speed: location.speed)
        self.setTraveledDistance(locations: locations)
        self._tempLocarion = locations.first
        #endif
        /*End Check*/
        if CMMotionActivityManager.isActivityAvailable() {
            
            self.motionActivityManager.startActivityUpdates(to: OperationQueue.main) { (activity) in
                
                guard let mActivity = activity else {return}
                
                if (mActivity.automotive) {
                    
                    status = StatusAction.Driving.rawValue
                    

                    self.dataUpdate?(location, "Foreground", status)
                    self.setDate()
                    self.setAvgSpeed(speed: location.speed)
                    self.setTraveledDistance(locations: locations)
                    self._tempLocarion = locations.first
                    
                }else if (mActivity.walking) {
                    status = StatusAction.Walking.rawValue
                }else {
                    status = StatusAction.General.rawValue
                    #if TARGET_OS_SIMULATOR
                    status = StatusAction.Driving.rawValue                    
                    self.dataUpdate?(location, "Foreground", status)
                    self.setDate()
                    self.setAvgSpeed(speed: location.speed)
                    self.setTraveledDistance(locations: locations)
                    self._tempLocarion = locations.first
                    #endif
                }
            }
        }
    }
    
    func createRegion(location:CLLocation?) {
        print("Location create a region")
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            
            let coordinate = CLLocationCoordinate2DMake((location?.coordinate.latitude)!, (location?.coordinate.longitude)!)
            let regionRadius = 100.0
            let region = CLCircularRegion(center: CLLocationCoordinate2D(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude),
                                          radius: regionRadius,
                                          identifier: "aabb")
            
            region.notifyOnExit = true
            region.notifyOnEntry = true
            
            //Stop your location manager for updating location and start regionMonitoring
            self.CLocationManager.stopUpdatingLocation()
            self.CLocationManager.startMonitoring(for: region)
        }
        else {
//            Analytics.logEvent("Region", parameters: ["Status" : "System can't track regions"])
        }
    }
    
    
    private func setAvgSpeed(speed: CLLocationSpeed){
        self._avgSpeed = (speed / 100)
        if self._avgSpeed > 0 {
            UserDefaults.standard.set(self._avgSpeed, forKey: MonitorKeys.AVGSpeed.rawValue)
        }else {
            self._avgSpeed = 0
        }
    }
    
    private func setDate() {
        if self._startDate == nil {
            self._startDate = Date()
        }
        
        let timeInterval = (Double(String(format: "%.0f", Date().timeIntervalSince(self._startDate).minute())) ?? 1)
        print("Time Interval: ",timeInterval)
        self._totalHrs += Double(Date().timeIntervalSince(self._startDate).minute())
        UserDefaults.standard.set(self._totalHrs, forKey: MonitorKeys.TotalHrs.rawValue)
    }
    
    private func setTraveledDistance(locations: [CLLocation]) {
        guard locations.first != nil else {return}
        guard let lastLocation = locations.last else {return}
        if _startLocation == nil {return}
        
        let lineDistance = (lastLocation.distance(from: self._startLocation) / 1000)
        if self._tempLocarion == nil {
            self._tempLocarion = locations.first
        }
        self._traveledDistance += (lastLocation.distance(from: self._tempLocarion) / 1000)
        
        if self._longestDistance < self._traveledDistance {
            self._longestDistance = self._traveledDistance
            UserDefaults.standard.set(self._longestDistance, forKey: MonitorKeys.LongDistance.rawValue)
        }
        print("line Distance: \(lineDistance)")
        print("traveled Distance: \(self._traveledDistance)")
        if self._longestDistance < self._traveledDistance {
            self._longestDistance = self._traveledDistance
            UserDefaults.standard.set(self._longestDistance, forKey: MonitorKeys.LongDistance.rawValue)
        }
        // total distance --> pause Move
        //UserDefaults.standard.set(self.totalDistance, forKey: MonitorKeys.TotalKM.rawValue)
    }
}
