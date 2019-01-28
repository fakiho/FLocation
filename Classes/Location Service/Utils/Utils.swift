//
//  Utils.swift
//  FLocation
//
//  Created by Ali Fakih on 1/28/19.
//

import Foundation
import UIKit
import UserNotifications

@available(iOS 11.0, *)
class Utils {
    
    static func scheduleLocalNotification(title:String, subtitle: String) {
        
        let notificationContent = UNMutableNotificationContent()
        
        notificationContent.sound = UNNotificationSound.default()
        notificationContent.title = title
        notificationContent.subtitle = subtitle
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let notificationRequest = UNNotificationRequest(identifier: "cocoacasts_local_notification", content: notificationContent, trigger: trigger)
        
        UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: nil)
    }
}

extension Date
{
    func dateAt(hours: Int, minutes: Int) -> Date
    {
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        
        //get the month/day/year componentsfor today's date.
        
        var date_components = calendar.components(
            [NSCalendar.Unit.year,
             NSCalendar.Unit.month,
             NSCalendar.Unit.day],
            from: self)
        
        //Create an NSDate for the specified time today.
        date_components.hour = hours
        date_components.minute = minutes
        date_components.second = 0
        
        let newDate = calendar.date(from: date_components)!
        return newDate
    }
}



extension String {
    var isBool: Bool {
        return Bool(self) != nil
    }
}
