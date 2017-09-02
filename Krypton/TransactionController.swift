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
    var currentExchangeValue: Double?
    var showsCurrentExchangeValue = false
    
    // MARK: - Outlets
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var senderField: UITextField!
    @IBOutlet weak var receiverField: UITextField!
    @IBOutlet weak var dateField: UITextField!
    @IBOutlet weak var typeField: UITextField!
    @IBOutlet weak var exchangeValueField: UITextField!
    @IBOutlet weak var blockField: UITextField!
    @IBOutlet weak var hashField: UITextField!
    @IBOutlet weak var exchangeValueTypeToggle: UIButton!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        navigationItem.rightBarButtonItem = editButtonItem
        
        if let tx = transaction {
            let cryptoCurrency = Currency.Crypto(rawValue: tx.owner!.cryptoCurrency!)!
            let unitSymbol = cryptoCurrency.symbol
            valueLabel.text = unitSymbol + " " + Format.cryptoFormatter.string(from: NSNumber(value: tx.value))!
            
            senderField.text = alias(for: tx.from!) ?? tx.from
            receiverField.text = alias(for: tx.from!) ?? tx.to
            
            dateField.text = Format.dateFormatter.string(from: tx.date! as Date)
            typeField.text = tx.type
            blockField.text = String(tx.block)
            hashField.text = tx.identifier
            
            if let exchangeValue = tx.exchangeValue {
                exchangeValueField.text = Format.fiatFormatter.string(from: NSNumber(value: exchangeValue))
            } else {
                exchangeValueField.text = "???"
            }
        }
    }
    
    // MARK: - Navigation
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        navigationItem.hidesBackButton = !navigationItem.hidesBackButton
        exchangeValueField.isEnabled = !exchangeValueField.isEnabled
        
//        if !editing {
//            exchangeValueTypeToggle.isEnabled = true
//            
//            if let newValue = Double(exchangeValueField.text!) {
//                transaction?.setUserExchangeValue(newValue, in: AppDelegate.viewContext)
//            }
//        } else {
//            exchangeValueTypeToggle.isEnabled = false
//        }
    }
    
    @IBAction func toggleExchangeValueType(_ sender: UIButton) {
        guard let tx = transaction else {
            return
        }
        
        showsCurrentExchangeValue = !showsCurrentExchangeValue
        
        if showsCurrentExchangeValue {
            if let currentExchangeValue = tx.currentExchangeValue {
                exchangeValueField.text = Format.fiatFormatter.string(from: NSNumber(value: currentExchangeValue))
            } else {
                exchangeValueField.text = "???"
            }
        } else {
            if let exchangeValue = tx.exchangeValue {
                exchangeValueField.text = Format.fiatFormatter.string(from: NSNumber(value: exchangeValue))
            } else {
                exchangeValueField.text = "???"
            }
        }
    }
    
    // MARK: - Private Methods
    private func alias(for address: String) -> String? {
        return addresses?.first(where: { $0.address == address })?.alias
    }
    
}
