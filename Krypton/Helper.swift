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
    /// formats dates locally without time
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// formats crypto currency values with 2-4 decimal digits, DOES NOT include currency symbol > use Currency.Crypto.symbol
    static let cryptoFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        return formatter
    }()
    
    /// formats fiat currency values according to set base currency (Wallet.baseCurrency)
    static let fiatFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Wallet.baseCurrency.rawValue
        return formatter
    }()
    
    /// formats numbers with 2 decimal digits
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
}

extension Date {
    
    // MARK: - Public Class Methods
    /// returns specified date in specified timezone but with set time of 0AM
    static func start(of date: Date, in timezone: TimeZone) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timezone
    
        let dateComponents = Calendar.current.dateComponents([.day, .month, .year], from: date)
        return calendar.date(from: dateComponents)!
    }
    
    /// returns successor of specified date in specified timezone but with set time of 0AM
    static func end(of date: Date, in timezone: TimeZone) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        
        let startDate = Date.start(of: date, in: timezone)
        return calendar.date(byAdding: .day, value: +1, to: startDate)!
    }
    
    // MARK: - Public Methods
    /// checks whether date is today according to current (system) calendar
    func isToday() -> Bool {
        return Calendar.current.compare(self, to: Date(), toGranularity: .day) == .orderedSame
    }
    
    /// checks whether date lays in future according to current (system) calendar
    func isFuture() -> Bool {
        return Calendar.current.compare(self, to: Date(), toGranularity: .day) == .orderedDescending
    }
    
}

extension NotificationCenter {
    
    // MARK: - Public Methods
    /// creates unique observer with specified selector by removing old observers
    func setObserver(_ observer: AnyObject, selector: Selector, name: NSNotification.Name, object: AnyObject?) {
        NotificationCenter.default.removeObserver(observer, name: name, object: object)
        NotificationCenter.default.addObserver(observer, selector: selector, name: name, object: object)
    }
    
}
