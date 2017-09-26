//
//  TransactionDetailController.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class TransactionDetailController: UITableViewController {

    // MARK: - Public Properties
    var transaction: Transaction?
    let exchangeValueIndexPath = IndexPath(row: 0, section: 2)
    let profitIndexPath = IndexPath(row: 1, section: 2)
    
    var showsExchangeValue = false {
        didSet {
            guard let currentExchangeValue = transaction?.currentExchangeValue, let exchangeValue = transaction?.exchangeValue else {
                exchangeValueField.text = "???"
                return
            }
            
            if showsExchangeValue {
                exchangeValueTypeLabel.text = "Value"
                exchangeValueField.text = Format.getFiatFormatting(for: NSNumber(value: exchangeValue), fiatCurrency: PortfolioManager.shared.baseCurrency)
            } else {
                exchangeValueTypeLabel.text = "Current Value"
                exchangeValueField.text = Format.getFiatFormatting(for: NSNumber(value: currentExchangeValue), fiatCurrency: PortfolioManager.shared.baseCurrency)
            }
        }
    }
    
    var showsRelativeProfit = true {
        didSet {
            guard let profitStats = transaction?.getProfitStats(timeframe: .allTime) else {
                profitField.text = "???"
                return
            }
            
            if showsRelativeProfit {
                profitTypeLabel.text = "Relative Profit"
                let relativeProfit = Format.relativeProfit(from: profitStats)
                profitField.text = Format.getNumberFormatting(for: NSNumber(value: relativeProfit)) + "%"
            } else {
                profitTypeLabel.text = "Absolute Profit"
                let absoluteProfit = Format.absoluteProfit(from: profitStats)
                profitField.text = Format.getFiatFormatting(for: NSNumber(value: absoluteProfit), fiatCurrency: PortfolioManager.shared.baseCurrency)
            }
        }
    }

    
    // MARK: - Outlets
    @IBOutlet weak var amountField: UILabel!
    @IBOutlet weak var dateField: UILabel!
    
    @IBOutlet weak var senderAddressField: UILabel!
    @IBOutlet weak var receiverAddressField: UILabel!
    @IBOutlet weak var typeField: UILabel!
    
    @IBOutlet weak var exchangeValueTypeLabel: UILabel!
    @IBOutlet weak var exchangeValueField: UILabel!
    @IBOutlet weak var profitTypeLabel: UILabel!
    @IBOutlet weak var profitField: UILabel!
    @IBOutlet weak var isInvestmentSwitch: UISwitch!
    
    @IBOutlet weak var blockNumberField: UILabel!
    @IBOutlet weak var hashNumberField: UILabel!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        guard let tx = transaction else {
            return
        }
        
        amountField.text = Format.getCryptoFormatting(for: NSNumber(value: tx.amount), cryptoCurrency: Currency.Crypto(rawValue: tx.owner!.cryptoCurrency!)!)
        
        senderAddressField.text = PortfolioManager.shared.getAlias(for: tx.from!) ?? tx.from
        receiverAddressField.text = PortfolioManager.shared.getAlias(for: tx.to!) ?? tx.to
        dateField.text = Format.getDateFormatting(for: tx.date! as Date)
        typeField.text = tx.type
        
        showsExchangeValue = true
        showsRelativeProfit = true
        isInvestmentSwitch.isOn = tx.isInvestment
        
        blockNumberField.text = String(tx.block)
        hashNumberField.text = tx.identifier
    }

    // MARK: - Navigation
    @IBAction func toggleIsInvestment(_ sender: UISwitch) {
        do {
            try transaction?.setIsInvestment(state: sender.isOn)
        } catch {
            print("Failed to save updated investment status.")
        }
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == exchangeValueIndexPath {
            showsExchangeValue = !showsExchangeValue
        }
        
        if indexPath == profitIndexPath {
            showsRelativeProfit = !showsRelativeProfit
        }
    }
    
//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        let decimalSeperator = NumberFormatter().decimalSeparator!
//        
//        if string.characters.count == 1 {
//            if string == decimalSeperator && (textField.text?.range(of: decimalSeperator) != nil) {
//                return false
//            } else {
//                return true
//            }
//        } else {
//            let char = string.cString(using: String.Encoding.utf8)!
//            let isBackSpace = strcmp(char, "\\b")
//            
//            if (isBackSpace == -92) {
//                // backspace pressed
//                return true
//            } else {
//                // pasted text
//                return false
//            }
//        }
//    }

//    override func setEditing(_ editing: Bool, animated: Bool) {
//        super.setEditing(editing, animated: animated)
//        
//        navigationItem.hidesBackButton = !navigationItem.hidesBackButton
//        exchangeValueField.isEnabled = !exchangeValueField.isEnabled
//        exchangeValueTypeToggle.isEnabled = !exchangeValueTypeToggle.isEnabled
//        
//        if editing {
//            showsCurrentExchangeValue = false
//        } else {
//            if let newValueString = exchangeValueField.text, let newValue = Format.numberFormatter.number(from: newValueString)  {
//                transaction?.setUserExchangeValue(value: Double(newValue))
//                showsCurrentExchangeValue = false
//            }
//        }
//    }
    
}
