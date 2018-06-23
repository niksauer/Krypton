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
    private func getNumberFormatter(minDigits: Int, maxDigits: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = minDigits
        formatter.maximumFractionDigits = maxDigits
        
        if maxDigits < minDigits {
            formatter.minimumFractionDigits = 0
        }
        
        return formatter
    }
    
    /// formats crypto currency values with 2-4 decimal digits
    private func getFormatting(for value: Double, blockchain: Blockchain, maxDigits: Int?) -> String? {
        let formatter = getNumberFormatter(minDigits: 2, maxDigits: maxDigits ?? blockchain.decimalDigits)
        formatter.numberStyle = .decimal

        if let formattedString = formatter.string(from: NSNumber(value: value)) {
            return "\(blockchain.symbol) \(formattedString)"
        } else {
            return nil
        }
    }
    
    /// formats fiat currency values according to set quote currency
    private func getFormatting(for value: Double, fiat: Fiat, maxDigits: Int?) -> String? {
        let formatter = getNumberFormatter(minDigits: 2, maxDigits: maxDigits ?? 2)
        formatter.numberStyle = .currency
        formatter.currencyCode = fiat.code
        return formatter.string(from: NSNumber(value: value))
    }
    
    private func getFormatting(for value: Double, token: TokenFeatures, maxDigits: Int?) -> String? {
        let formatter = getNumberFormatter(minDigits: 2, maxDigits: maxDigits ?? token.decimalDigits)
        formatter.numberStyle = .decimal
  
        if let formattedString = formatter.string(from: NSNumber(value: value)) {
            return "\(formattedString) \(token.code)"
        } else {
            return nil
        }
    }
    
    /// formats numbers with 2 decimal digits
    private func getNumberFormatting(for value: Double, maxDigits: Int?) -> String? {
        let formatter = getNumberFormatter(minDigits: 2, maxDigits: maxDigits ?? 2)
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value))
    }
    
    private func getMaxDigits(for value: Double) -> Int {
        if -100 < value && value < 100 {
            return 2
        } else {
            return 0
        }
    }
    
    // MARK: - Public Methods
    func getFormatting(for value: Double, currency: Currency, maxDigits: Int? = nil) -> String? {
        switch currency {
        case let fiatCurrency as Fiat:
            return getFormatting(for: value, fiat: fiatCurrency, maxDigits: maxDigits)
        case let blockchain as Blockchain:
            return getFormatting(for: value, blockchain: blockchain, maxDigits: maxDigits)
        case let token as TokenFeatures:
            return getFormatting(for: value, token: token, maxDigits: maxDigits)
        default:
            return nil
        }
    }

    func getPercentageFormatting(for value: Double, maxDigits: Int? = nil) -> String? {
        if let numberString = getNumberFormatting(for: value, maxDigits: maxDigits) {
            return numberString + "%"
        } else {
            return nil
        }
    }
    
}
