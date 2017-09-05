//
//  TransactionController.swift
//  Krypton
//
//  Created by Niklas Sauer on 22.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit
import CoreData

class TransactionController: UIViewController, UITextFieldDelegate {

    // MARK: - Properties
    var addresses: [Address]?
    var transaction: Transaction?
    var currentExchangeValue: Double?
    var showsCurrentExchangeValue = false {
        didSet {
            if showsCurrentExchangeValue {
                if let currentExchangeValue = transaction?.currentExchangeValue {
                    exchangeValueField.text = Format.fiatFormatter.string(from: NSNumber(value: currentExchangeValue))
                } else {
                    exchangeValueField.text = "???"
                }
            } else {
                if let userExchangeValue = transaction?.userExchangeValue, userExchangeValue != -1 {
                    exchangeValueField.text = Format.fiatFormatter.string(from: NSNumber(value: userExchangeValue))
                } else if let exchangeValue = transaction?.exchangeValue {
                    exchangeValueField.text = Format.fiatFormatter.string(from: NSNumber(value: exchangeValue))
                } else {
                    exchangeValueField.text = "???"
                }
            }
        }
    }

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
        exchangeValueField.delegate = self
        
        guard let tx = transaction else {
            return
        }
        
        let cryptoCurrency = Currency.Crypto(rawValue: tx.owner!.cryptoCurrency!)!
        let unitSymbol = cryptoCurrency.symbol
        valueLabel.text = unitSymbol + " " + Format.cryptoFormatter.string(from: NSNumber(value: tx.value))!
        
        senderField.text = alias(for: tx.from!) ?? tx.from
        receiverField.text = alias(for: tx.from!) ?? tx.to
        
        dateField.text = Format.dateFormatter.string(from: tx.date! as Date)
        typeField.text = tx.type
        blockField.text = String(tx.block)
        hashField.text = tx.identifier
        
        showsCurrentExchangeValue = false
    }
    
    // MARK: - Navigation
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        navigationItem.hidesBackButton = !navigationItem.hidesBackButton
        exchangeValueField.isEnabled = !exchangeValueField.isEnabled
        exchangeValueTypeToggle.isEnabled = !exchangeValueTypeToggle.isEnabled

        if editing {
            if showsCurrentExchangeValue {
                showsCurrentExchangeValue = false
            }
        } else {
            if let newValueString = exchangeValueField.text, let newValue = Double(newValueString) {
                transaction?.setUserExchangeValue(newValue, in: AppDelegate.viewContext)
                showsCurrentExchangeValue = false
            }
        }
    }
    
    @IBAction func toggleExchangeValueType(_ sender: UIButton) {
        showsCurrentExchangeValue = !showsCurrentExchangeValue
    }
    
    // MARK: - Private Methods
    private func alias(for address: String) -> String? {
        return addresses?.first(where: { $0.address == address })?.alias
    }
    
    // MARK: - exchangeValueField Delegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let decimalSeperator = NumberFormatter().decimalSeparator!
        
        if string.characters.count == 1 {
            if string == decimalSeperator && (textField.text?.range(of: decimalSeperator) != nil) {
                return false
            } else {
                return true
            }
        } else {
            let char = string.cString(using: String.Encoding.utf8)!
            let isBackSpace = strcmp(char, "\\b")
            
            if (isBackSpace == -92) {
                // backspace pressed
                return true
            } else {
//                if string.range(of: decimalSeperator) != nil {
//                    
//                }
                return false
            }
        }
    }
    
}
