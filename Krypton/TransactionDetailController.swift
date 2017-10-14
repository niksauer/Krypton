//
//  TransactionDetailController.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class TransactionDetailController: UITableViewController, TickerWatchlistDelegate, UITextFieldDelegate {

    // MARK: - Private Properties
    let exchangeValueIndexPath = IndexPath(row: 0, section: 2)
    let profitIndexPath = IndexPath(row: 1, section: 2)
    let feeIndexPath = IndexPath(row: 0, section: 3)
    
    // MARK: - Public Properties
    var transaction: Transaction!
    
    var showsExchangeValue = false {
        didSet {
            guard let currentExchangeValue = transaction?.currentExchangeValue, let exchangeValue = transaction?.exchangeValue else {
                exchangeValueField.text = "???"
                return
            }
            
            if showsExchangeValue {
                exchangeValueTypeLabel.text = "Value"
                exchangeValueField.text = Format.getCurrencyFormatting(for: exchangeValue, currency: transaction.owner!.baseCurrency)
            } else {
                exchangeValueTypeLabel.text = "Current Value"
                exchangeValueField.text = Format.getCurrencyFormatting(for: currentExchangeValue, currency: transaction.owner!.baseCurrency)
            }
        }
    }
    
    var showsRelativeProfit = true {
        didSet {
            guard let profitStats = transaction?.getProfitStats(timeframe: .allTime) else {
                profitLabel.text = "???"
                return
            }
            
            if showsRelativeProfit {
                profitTypeLabel.text = "Relative Profit"
                profitLabel.text = Format.getRelativeProfitFormatting(from: profitStats)
            } else {
                profitTypeLabel.text = "Absolute Profit"
                profitLabel.text = Format.getAbsoluteProfitFormatting(from: profitStats, currency: transaction.owner!.baseCurrency)
            }
        }
    }
    
    var showsCryptoFees = true {
        didSet {
            guard let feeAmount = transaction?.feeAmount, let feeExchangeValue = transaction?.feeExchangeValue else {
                feeLabel.text = "???"
                return
            }
            
            if showsCryptoFees {
                feeLabel.text = Format.getCurrencyFormatting(for: feeAmount, currency: transaction.owner!.baseCurrency)
            } else {
                feeLabel.text = Format.getCurrencyFormatting(for: feeExchangeValue, currency: transaction.owner!.baseCurrency)
            }
        }
    }
    
    // MARK: - Outlets
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var senderAddressLabel: UILabel!
    @IBOutlet weak var receiverAddressLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    
    @IBOutlet weak var exchangeValueTypeLabel: UILabel!
    @IBOutlet weak var exchangeValueLabel: UILabel!
    @IBOutlet weak var exchangeValueField: UITextField!
    @IBOutlet weak var profitTypeLabel: UILabel!
    @IBOutlet weak var profitLabel: UILabel!
    @IBOutlet weak var isInvestmentSwitch: UISwitch!
    
    @IBOutlet weak var feeLabel: UILabel!
    @IBOutlet weak var executedLabel: UILabel!
    @IBOutlet weak var blockNumberLabel: UILabel!
    @IBOutlet weak var identifierLabel: UILabel!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        exchangeValueField.delegate = self
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        guard let tx = transaction else {
            return
        }
        
        TickerWatchlist.delegate = self

        amountLabel.text = Format.getCurrencyFormatting(for: tx.amount, currency: transaction!.owner!.blockchain)
        senderAddressLabel.text = PortfolioManager.shared.getAlias(for: tx.from!) ?? tx.from
        receiverAddressLabel.text = PortfolioManager.shared.getAlias(for: tx.to!) ?? tx.to
        dateLabel.text = Format.getDateFormatting(for: tx.date! as Date)
        typeLabel.text = tx.type
        
        isInvestmentSwitch.isOn = tx.isInvestment
    
        executedLabel.text = String(tx.isError)
        blockNumberLabel.text = String(tx.block)
        identifierLabel.text = tx.identifier
        
        updateUI()
    }

    // MARK: - Navigation
    @IBAction func toggleIsInvestment(_ sender: UISwitch) {
        do {
            try transaction?.setIsInvestment(state: sender.isOn)
        } catch {
            // present error
            print(error)
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        navigationItem.hidesBackButton = !navigationItem.hidesBackButton
        
        if editing {
            showsExchangeValue = true
            exchangeValueField.isHidden = true
            exchangeValueField.text = exchangeValueField.text
            exchangeValueField.isHidden = false
        } else {
            if let newValueString = exchangeValueField.text?.trimmingCharacters(in: .whitespacesAndNewlines), let newValue = Double(newValueString) {
                do {
                    try transaction?.setUserExchangeValue(value: newValue)
                } catch {
                    // present error
                    print(error)
                }
            }
            
            showsExchangeValue = { showsExchangeValue }()
            exchangeValueField.isHidden = true
            exchangeValueField.resignFirstResponder()
            exchangeValueField.isHidden = false
        }
    }
    
    // MARK: - Public Methods
    func updateUI() {
        showsExchangeValue = { showsExchangeValue }()
        showsRelativeProfit = { showsRelativeProfit }()
        showsCryptoFees = { showsCryptoFees }()
    }
    
    // MARK: - TableView Delegate
    func didUpdateCurrentPrice(for tradingPair: TradingPair) {
        updateUI()
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case _ where indexPath == exchangeValueIndexPath:
            showsExchangeValue = !showsExchangeValue
        case _ where indexPath == profitIndexPath:
            showsRelativeProfit = !showsRelativeProfit
        case _ where indexPath == feeIndexPath:
            showsCryptoFees = !showsCryptoFees
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    // MARK: - TextField Delegate
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
