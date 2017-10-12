//
//  Globals.swift
//  Krypton
//
//  Created by Niklas Sauer on 26.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

enum ProfitTimeframe {
    case allTime
    case sinceDate(Date)
}

struct Format {
    
    // MARK: - Private Static Methods
    /// formats crypto currency values with 2-4 decimal digits
    private static func getCryptoFormatting(for value: Double, blockchain: Blockchain) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 8
        return blockchain.symbol + " " + formatter.string(from: NSNumber(value: value))!
    }
    
    /// formats fiat currency values according to set base currency
    private static func getFiatFormatting(for value: Double, fiatCurrency: Fiat) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = fiatCurrency.code
        return formatter.string(from: NSNumber(value: value))!
    }
    
    private static func getTokenFormatting(for value: Double, token: Token) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 8
        return formatter.string(from: NSNumber(value: value))! + " " + token.code
    }
    
    // MARK: - Public Static Methods
    /// formats numbers with 2 decimal digits    
    static func getNumberFormatting(for value: NSNumber) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value)!
    }
    
    /// formats dates locally without time
    static func getDateFormatting(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    static func getCurrencyFormatting(for value: Double, currency: Currency) -> String? {
        if let fiatCurrency = Fiat(rawValue: currency.code) {
            return getFiatFormatting(for: value, fiatCurrency: fiatCurrency)
        } else if let blockchain = Blockchain(rawValue: currency.code) {
            return getCryptoFormatting(for: value, blockchain: blockchain)
        } else if let token = currency as? Token {
            return getTokenFormatting(for: value, token: token)
        } else {
            return nil
        }
    }
    
    static func getAbsoluteProfit(from: (startValue: Double, endValue: Double)) -> Double {
        return from.endValue - from.startValue
    }
    
    static func getRelativeProfit(from: (startValue: Double, endValue: Double)) -> Double {
        return (from.endValue - from.startValue) / from.startValue * 100
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
