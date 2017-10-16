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
    private var exchangeValueIndexPath: IndexPath!
    private var profitIndexPath: IndexPath!
    private var feeIndexPath: IndexPath!
    
    // MARK: - Public Properties
    var transaction: Transaction!
    var showsExchangeValue = true
    var showsRelativeProfit = true
    var showsCryptoFees = true
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        TickerWatchlist.delegate = self
    
//        exchangeValueField.delegate = self
//        self.navigationItem.rightBarButtonItem = self.editButtonItem

    }

    // MARK: - Navigation
    @IBAction func toggleIsInvestment(_ state: Bool) {
        do {
            try transaction?.setIsInvestment(state: state)
        } catch {
            // present error
        }
    }
    
//    override func setEditing(_ editing: Bool, animated: Bool) {
//        super.setEditing(editing, animated: animated)
//
//        navigationItem.hidesBackButton = !navigationItem.hidesBackButton
//
//        if editing {
//            showsExchangeValue = true
//            exchangeValueField.isHidden = true
//            exchangeValueField.text = exchangeValueField.text
//            exchangeValueField.isHidden = false
//        } else {
//            if let newValueString = exchangeValueField.text?.trimmingCharacters(in: .whitespacesAndNewlines), let newValue = Double(newValueString) {
//                do {
//                    try transaction?.setUserExchangeValue(value: newValue)
//                } catch {
//                    // present error
//                }
//            }
//
//            showsExchangeValue = { showsExchangeValue }()
//            exchangeValueField.isHidden = true
//            exchangeValueField.resignFirstResponder()
//            exchangeValueField.isHidden = false
//        }
//    }
    
    // MARK: - Public Methods
    func updateUI() {
        tableView.reloadData()
    }
    
    // MARK: - TickerWatchlist Delegate
    func didUpdateCurrentPrice(for tradingPair: TradingPair) {
        updateUI()
    }
    
    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case _ where section == 0:
            return 1
        case _ where section == 1:
            switch transaction.owner! {
            case is TokenAddress:
                return 3
            default:
                return 2
            }
        case _ where section == 2:
            return 3
        case _ where section == 3:
            return 4
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        
        switch section {
        case _ where section == 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "transactionHeaderCell", for: indexPath) as! TransactionHeaderCell
            cell.configure(amount: transaction.amount, currency: transaction.owner!.blockchain, date: transaction.date!)
            return cell
        case _ where section == 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath)
            
            switch row {
            case _ where row == 0:
                cell.textLabel?.text = "Sender"
                cell.detailTextLabel?.text = PortfolioManager.shared.getAlias(for: transaction.from!) ?? transaction.from
            case _ where row == 1:
                cell.textLabel?.text = "Receiver"
                cell.detailTextLabel?.text = PortfolioManager.shared.getAlias(for: transaction.to!) ?? transaction.to
            case _ where row == 2 && transaction.owner! is TokenAddress:
                cell.textLabel?.text = "Type"
                cell.detailTextLabel?.text = transaction.type
            default:
                break
            }
            
            return cell
        case _ where section == 2:
            switch row {
            case _ where row == 0:
                exchangeValueIndexPath = indexPath
                let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath)
                
                guard let exchangeValue = transaction.exchangeValue, let currentExchangeValue = transaction.currentExchangeValue else {
                    cell.textLabel?.text = "Value"
                    cell.detailTextLabel?.text = "???"
                    return cell
                }
                
                if showsExchangeValue {
                    cell.textLabel?.text = "Value"
                    cell.detailTextLabel?.text = Format.getCurrencyFormatting(for: exchangeValue, currency: transaction.owner!.baseCurrency)
                } else {
                    cell.textLabel?.text = "Current Value"
                    cell.detailTextLabel?.text = Format.getCurrencyFormatting(for: currentExchangeValue, currency: transaction.owner!.baseCurrency)
                }
                
                return cell
            case _ where row == 1:
                profitIndexPath = indexPath
                let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath)
                
                guard let profitStats = transaction.getProfitStats(timeframe: .allTime) else {
                    cell.textLabel?.text = "Profit"
                    cell.detailTextLabel?.text = "???"
                    return cell
                }
                
                if showsRelativeProfit {
                    cell.textLabel?.text = "Relative Profit"
                    cell.detailTextLabel?.text = Format.getRelativeProfitFormatting(from: profitStats)
                } else {
                    cell.textLabel?.text = "Absolute Profit"
                    cell.detailTextLabel?.text = Format.getAbsoluteProfitFormatting(from: profitStats, currency: transaction.owner!.baseCurrency)
                }
                
                return cell
            case _ where row == 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath) as! SwitchCell
                cell.configure(name: "Investment", isOn: transaction.isInvestment, completion: toggleIsInvestment)
                return cell
            default:
                // not valid
                return UITableViewCell()
            }
        case _ where section == 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath)
            
            switch row {
            case _ where row == 0:
                cell.textLabel?.text = "Fee"
                
                guard let feeExchangeValue = transaction.feeExchangeValue else {
                    cell.detailTextLabel?.text = "???"
                    break
                }
                
                if showsCryptoFees {
                    cell.detailTextLabel?.text = Format.getCurrencyFormatting(for: transaction.feeAmount, currency: transaction.owner!.blockchain)
                } else {
                    cell.detailTextLabel?.text = Format.getCurrencyFormatting(for: feeExchangeValue, currency: transaction.owner!.baseCurrency)
                }
                
                feeIndexPath = indexPath
            case _ where row == 1:
                cell.textLabel?.text = "Executed"
                cell.detailTextLabel?.text = String(!transaction.isError)
            case _ where row == 2:
                cell.textLabel?.text = "Block"
                cell.detailTextLabel?.text = String(transaction.block)
            case _ where row == 3:
                cell.textLabel?.text = "Hash"
                cell.detailTextLabel?.text = transaction.identifier
            default:
                // not valid
                return UITableViewCell()
            }
    
            return cell
        default:
            // not valid
            return UITableViewCell()
        }
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath == IndexPath(row: 0, section: 0) else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
        
        return 70
    }
    
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
        
        updateUI()
    }
    
//    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        return false
//    }
    
    // MARK: - TextField Delegate
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
    
}
