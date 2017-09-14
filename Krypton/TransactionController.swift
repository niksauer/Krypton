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
    var transaction: Transaction?
    
    var showsCurrentExchangeValue = false {
        didSet {
            guard let currentExchangeValue = transaction?.currentExchangeValue, let exchangeValue = transaction?.exchangeValue else {
                exchangeValueField.text = "???"
                return
            }
        
            if showsCurrentExchangeValue {
                exchangeValueField.text = Format.fiatFormatter.string(from: NSNumber(value: currentExchangeValue))
            } else {
                exchangeValueField.text = Format.fiatFormatter.string(from: NSNumber(value: exchangeValue))
            }
        }
    }
    
    var showsRelativeProfit = true {
        didSet {
            guard let profitStats = transaction?.getProfitStats(timeframe: .allTime) else {
                profitValueField.text = "???"
                return
            }
            
            if showsRelativeProfit {
                let relativeProfit = Format.relativeProfit(from: profitStats)
                profitValueField.text = Format.numberFormatter.string(from: NSNumber(value: relativeProfit))! + "%"
            } else {
                let absoluteProfit = Format.absoluteProfit(from: profitStats)
                profitValueField.text = Format.fiatFormatter.string(from: NSNumber(value: absoluteProfit))
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
    @IBOutlet weak var profitValueField: UITextField!
    @IBOutlet weak var isInvestmentToggle: UISwitch!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        navigationItem.rightBarButtonItem = editButtonItem
        exchangeValueField.delegate = self
        
        guard let tx = transaction else {
            return
        }
        
        let cryptoCurrency = Currency.Crypto(rawValue: tx.owner!.cryptoCurrency!)!
        let unitSymbol = cryptoCurrency.symbol
        valueLabel.text = unitSymbol + " " + Format.cryptoFormatter.string(from: NSNumber(value: tx.amount))!
        
        senderField.text = PortfolioManager.shared.alias(for: tx.from!) ?? tx.from
        receiverField.text = PortfolioManager.shared.alias(for: tx.to!) ?? tx.to
        
        dateField.text = Format.dateFormatter.string(from: tx.date! as Date)
        typeField.text = tx.type
        blockField.text = String(tx.block)
        hashField.text = tx.identifier
        
        isInvestmentToggle.isOn = tx.isInvestment
        
        showsCurrentExchangeValue = false
        showsRelativeProfit = true
    }
    
    // MARK: - Navigation
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        navigationItem.hidesBackButton = !navigationItem.hidesBackButton
        exchangeValueField.isEnabled = !exchangeValueField.isEnabled
        exchangeValueTypeToggle.isEnabled = !exchangeValueTypeToggle.isEnabled

        if editing {
            showsCurrentExchangeValue = false
        } else {
            if let newValueString = exchangeValueField.text, let newValue = Format.numberFormatter.number(from: newValueString)  {
                transaction?.setUserExchangeValue(value: Double(newValue))
                showsCurrentExchangeValue = false
            }
        }
    }
    
    @IBAction func toggleExchangeValueType(_ sender: UIButton) {
        showsCurrentExchangeValue = !showsCurrentExchangeValue
    }
    
    @IBAction func toggleProfitValueType(_ sender: UIButton) {
        showsRelativeProfit = !showsRelativeProfit
    }
    
    
    @IBAction func toggleIsInvestment(_ sender: UISwitch) {
        transaction?.setIsInvestment(state: sender.isOn)
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
                // pasted text
                return false
            }
        }
    }
    
}
