//
//  UpdateStatusDateFormatter.swift
//  Krypton
//
//  Created by Niklas Sauer on 06.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

class UpdateStatusDateFormatter: DateFormatter {
    override func string(from date: Date) -> String {
        let calendar = NSCalendar.current
        let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .weekOfYear, .month, .year, .second]
        let now = Date()
        let earliest = now < date ? now : date
        let latest = (earliest == now) ? date : now
        let components = calendar.dateComponents(unitFlags, from: earliest,  to: latest)
        
        if (components.minute! >= 3) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .short
            return "Updated at \(dateFormatter.string(from: earliest))"
        } else if (components.minute! >= 1) {
            return "Updated \(components.minute!) minute\(components.minute! >= 2 ? "s" : "") ago "
        } else {
            return "Updated Just Now"
        }
    }
}
