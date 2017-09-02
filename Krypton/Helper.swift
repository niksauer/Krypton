//
//  Helper.swift
//  Krypton
//
//  Created by Niklas Sauer on 26.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

struct Format {
    
    // MARK: - Public Properties
    /// formats dates, disregards time
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// formats crypto currency values with 2-4 decimal digits, DOES NOT include currency symbol > use Currency.symbol(for:)
    static let cryptoFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        return formatter
    }()
    
    /// formats fiat currency values according to specified wallet base currency
    static let fiatFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Wallet.baseCurrency.rawValue
        return formatter
    }()
    
    /// formats number with 2 decimal digits 
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
}

extension Date {
    static func start(of date: Date, in timezone: TimeZone) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timezone
    
        let dateComponents = Calendar.current.dateComponents([.day, .month, .year], from: date)
        return calendar.date(from: dateComponents)!
    }
    
    static func end(of date: Date, in timezone: TimeZone) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        
        let startDate = Date.start(of: date, in: timezone)
        return calendar.date(byAdding: .day, value: +1, to: startDate)!
    }
    
    func isToday() -> Bool {
        return Calendar.current.compare(self, to: Date(), toGranularity: .day) == .orderedSame
    }
    
    func isFuture() -> Bool {
        return Calendar.current.compare(self, to: Date(), toGranularity: .day) == .orderedDescending
    }
}

extension NotificationCenter {
    func setObserver(_ observer: AnyObject, selector: Selector, name: NSNotification.Name, object: AnyObject?) {
        NotificationCenter.default.removeObserver(observer, name: name, object: object)
        NotificationCenter.default.addObserver(observer, selector: selector, name: name, object: object)
    }
}
