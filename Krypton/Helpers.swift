//
//  Helpers.swift
//  Krypton
//
//  Created by Niklas Sauer on 26.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

struct Format {
    
    // MARK: - Private Static Methods
    /// formats crypto currency values with 2-4 decimal digits
    private static func getCryptoFormatting(for value: Double, blockchain: Blockchain) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = blockchain.decimalDigits
        
        if let formattedString = formatter.string(from: NSNumber(value: value)) {
            return "\(blockchain.symbol) \(formattedString)"
        } else {
            return nil
        }
    }
    
    /// formats fiat currency values according to set base currency
    private static func getFiatFormatting(for value: Double, fiatCurrency: Fiat) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = fiatCurrency.code
        return formatter.string(from: NSNumber(value: value))
    }
    
    private static func getTokenFormatting(for value: Double, token: Token) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = token.decimalDigits
        
        if let formattedString = formatter.string(from: NSNumber(value: value)) {
            return "\(formattedString) \(token.code)"
        } else {
            return nil
        }
    }
    
    /// formats numbers with 2 decimal digits
    private static func getNumberFormatting(for value: Double) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value))
    }
    
    // MARK: - Public Static Methods
    /// formats dates locally without time
    static func getDateFormatting(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    static func getCurrencyFormatting(for value: Double, currency: Currency) -> String? {
        switch currency {
        case let fiatCurrency as Fiat:
            return getFiatFormatting(for: value, fiatCurrency: fiatCurrency)
        case let blockchain as Blockchain:
            return getCryptoFormatting(for: value, blockchain: blockchain)
        case let token as Token:
            return getTokenFormatting(for: value, token: token)
        default:
            return nil
        }
    }
    
    static func getAbsoluteProfitFormatting(from: (startValue: Double, endValue: Double), currency: Currency) -> String? {
        return getCurrencyFormatting(for: (from.endValue - from.startValue), currency: currency)
    }
    
    static func getRelativeProfitFormatting(from: (startValue: Double, endValue: Double)) -> String? {
        if let percentage = getNumberFormatting(for: ((from.endValue - from.startValue) / from.startValue * 100)) {
            return percentage + "%"
        } else {
            return nil
        }
    }
    
}

extension Date {
    
    // MARK: - Public Properties
    /// returns specified date in specified timezone but with set time of 0AM
    var UTCStart: Date {
        var calendar = Calendar(identifier: .gregorian)
        let timezone = TimeZone(abbreviation: "UTC")!
        calendar.timeZone = timezone
        let dateComponents = calendar.dateComponents([.day, .month, .year], from: self)
        return calendar.date(from: dateComponents)!
    }
    
    /// returns successor of specified date in specified timezone but with set time of 0AM
    var UTCEnd: Date {
        var calendar = Calendar(identifier: .gregorian)
        let timezone = TimeZone(abbreviation: "UTC")!
        calendar.timeZone = timezone
        return calendar.date(byAdding: .day, value: +1, to: self.UTCStart)!
    }
    
    var isUTCToday: Bool {
        var calendar = Calendar(identifier: .gregorian)
        let timezone = TimeZone(abbreviation: "UTC")!
        calendar.timeZone = timezone
        return calendar.compare(self, to: Date(), toGranularity: .day) == .orderedSame
    }
    
    var isUTCFuture: Bool {
        var calendar = Calendar(identifier: .gregorian)
        let timezone = TimeZone(abbreviation: "UTC")!
        calendar.timeZone = timezone
        return calendar.compare(self, to: Date(), toGranularity: .day) == .orderedDescending
    }
    
    /// checks whether date is today according to current (system) calendar
    var isToday: Bool {
        return Calendar.current.compare(self, to: Date(), toGranularity: .day) == .orderedSame
    }
    
    /// checks whether date lays in future according to current (system) calendar
    var isFuture: Bool {
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

extension Data {
    
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
}

extension String {
    
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }

}
