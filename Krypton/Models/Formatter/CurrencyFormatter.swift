//
//  CurrencyFormatter.swift
//  Krypton
//
//  Created by Niklas Sauer on 26.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation

struct CurrencyFormatter {
    
    // MARK: - Private Methods
    /// formats crypto currency values with 2-4 decimal digits
    private func getFormatting(for value: Double, currency: Blockchain, maxDigits: Int? = nil) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = maxDigits ?? currency.decimalDigits
        
        if let formattedString = formatter.string(from: NSNumber(value: value)) {
            return "\(currency.symbol) \(formattedString)"
        } else {
            return nil
        }
    }
    
    /// formats fiat currency values according to set quote currency
    private func getFormatting(for value: Double, currency: Fiat) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        return formatter.string(from: NSNumber(value: value))
    }
    
    private func getFormatting(for value: Double, currency: TokenFeatures, maxDigits: Int? = nil) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = maxDigits ?? currency.decimalDigits
        
        if let formattedString = formatter.string(from: NSNumber(value: value)) {
            return "\(formattedString) \(currency.code)"
        } else {
            return nil
        }
    }
    
    /// formats numbers with 2 decimal digits
    private func getNumberFormatting(for value: Double, digits: Int?) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value))
    }
    
    // MARK: - Public Methods
    func getFormatting(for value: Double, currency: Currency, maxDigits: Int? = nil) -> String? {
        switch currency {
        case let fiatCurrency as Fiat:
            return getFormatting(for: value, currency: fiatCurrency)
        case let blockchain as Blockchain:
            return getFormatting(for: value, currency: blockchain, maxDigits: maxDigits)
        case let token as TokenFeatures:
            return getFormatting(for: value, currency: token, maxDigits: maxDigits)
        default:
            return nil
        }
    }

    func getAbsoluteProfitFormatting(from: (startValue: Double, endValue: Double), currency: Currency) -> String? {
        return getFormatting(for: (from.endValue - from.startValue), currency: currency)
    }
    
    func getRelativeProfitFormatting(from: (startValue: Double, endValue: Double)) -> String? {
        let percentage = ((from.startValue - from.endValue) / from.startValue * 100)
        let result: Double
        
        if from.startValue < from.endValue {
            result = abs(percentage)
        } else if from.startValue > from.endValue {
            result = -abs(percentage)
        } else {
            result = 0
        }
        
        if let numberString = getNumberFormatting(for: result, digits: 2) {
            return numberString + "%"
        } else {
            return nil
        }
    }
    
}
