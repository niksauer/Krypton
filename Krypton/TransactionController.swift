//
//  TransactionController.swift
//  Krypton
//
//  Created by Niklas Sauer on 22.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit
import CoreData

class TransactionController: UIViewController {

    // MARK: - Properties
    var addresses: [Address]?
    var transaction: Transaction?
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        return formatter
    }()
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    // MARK: - Outlets
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var senderField: UITextField!
    @IBOutlet weak var receiverField: UITextField!
    @IBOutlet weak var dateField: UITextField!
    @IBOutlet weak var typeField: UITextField!
    @IBOutlet weak var exchangeValueField: UITextField!
    @IBOutlet weak var blockField: UITextField!
    @IBOutlet weak var hashField: UITextField!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        if let tx = transaction {
            let cryptoCurrency = Currency.Crypto(rawValue: tx.owner!.cryptoCurrency!)!
            let unitSymbol = Currency.getSymbol(for: cryptoCurrency)!
            valueLabel.text = numberFormatter.string(from: NSNumber(value: tx.value))! + " " + unitSymbol
            senderField.text = tx.from
            receiverField.text = tx.to
            dateField.text = dateFormatter.string(from: tx.date! as Date)
            typeField.text = tx.type
            blockField.text = String(tx.block)
            hashField.text = tx.identifier
            
            let exchangeValue: Double?
            if tx.userExchangeValue != 0 {
                exchangeValue = tx.userExchangeValue
            } else {
                let baseCurrency = Currency.getBaseCurrency()
                let tradingPair = Currency.getTradingPair(cryptoCurrency: cryptoCurrency, fiatCurrency: baseCurrency)!
                exchangeValue = getExchangeValue(for: tradingPair, on: tx.date!)
            }
            
            exchangeValueField.text = numberFormatter.string(from: NSNumber(value: exchangeValue ?? 0))
            
        }

    }

    @IBAction func edit(_ sender: UIBarButtonItem) {
        exchangeValueField.isEnabled = true
    }
    
    private func getExchangeValue(for tradingPair: Currency.TradingPair, on date: NSDate) -> Double? {
        let context = AppDelegate.viewContext
        let request: NSFetchRequest<TickerPrice> = TickerPrice.fetchRequest()
        request.predicate = NSPredicate(format: "tradingPair = %@ AND date = %@", tradingPair.rawValue, date)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count >= 1, "Address.addAddress -- Database Inconsistency")
                return matches[0].value
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
}
