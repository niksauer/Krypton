//
//  TransactionDetailController.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

class TransactionDetailViewController: UITableViewController, UITextFieldDelegate, KryptonDaemonDelegate, TickerDaemonDelegate, BlockchainDaemonDelegate {
   
    // MARK: - Private Properties
    private var sendersIndexPath: IndexPath!
    private var receiversIndexPath: IndexPath!
    private var exchangeValueIndexPath: IndexPath!
    private var profitIndexPath: IndexPath!
    private var feeIndexPath: IndexPath!
    private var blockIndexPath: IndexPath!
    
    private var valueSaveAction: UIAlertAction!
    
    // MARK: - Private Properties
    private let viewFactory: ViewControllerFactory
    private let transaction: Transaction
    private let kryptonDaemon: KryptonDaemon
    private let portfolioManager: PortfolioManager
    private let tickerDaemon: TickerDaemon
    private let blockchainDaemon: BlockchainDaemon
    private let currencyFormatter: CurrencyFormatter
    private let dateFormatter: DateFormatter
    
    // MARK: - Public Properties
    var showsExchangeValue = true
    var showsRelativeProfit = true
    var showsCryptoFees = true
    var showsBlockNumber = true
    
    // MARK: - Initialization
    init(viewFactory: ViewControllerFactory, transaction: Transaction, kryptonDaemon: KryptonDaemon, portfolioManager: PortfolioManager, tickerDaemon: TickerDaemon, blockchainDaemon: BlockchainDaemon, currencyFormatter: CurrencyFormatter, dateFormatter: DateFormatter) {
        self.viewFactory = viewFactory
        self.transaction = transaction
        self.kryptonDaemon = kryptonDaemon
        self.portfolioManager = portfolioManager
        self.tickerDaemon = tickerDaemon
        self.blockchainDaemon = blockchainDaemon
        self.currencyFormatter = currencyFormatter
        self.dateFormatter = dateFormatter
        
        super.init(style: .grouped)
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "TransactionHeaderCell", bundle: nil), forCellReuseIdentifier: "TransactionHeaderCell")
        
        kryptonDaemon.delegate = self
        tickerDaemon.delegate = self
        blockchainDaemon.delegate = self
        
        if transaction.isUnread {
            do {
                try transaction.setIsUnread(state: false)
            } catch {
                // present error
            }
        }
        
        let flexibleSpacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let investmentButton = UIBarButtonItem(image: #imageLiteral(resourceName: "OT_label"), style: .plain, target: self, action: #selector(toggleIsInvestment))
        let exchangeValueButton = UIBarButtonItem(image: #imageLiteral(resourceName: "OT_money-bag"), style: .plain, target: self, action: #selector(showExchangeValueActionSheet))
        let readButton = UIBarButtonItem(image: #imageLiteral(resourceName: "OT_double-tick"), style: .plain, target: self, action: #selector(toggleIsUnread))
        
        self.toolbarItems = [investmentButton, flexibleSpacer, exchangeValueButton, flexibleSpacer, readButton]
        self.navigationController?.setToolbarHidden(false, animated: true)
    }

    // MARK: - Private Methods
    // MARK: UI Initialization
    private func updateUI() {
        tableView.reloadData()
    }
    
    // MARK: Content Interaction
    @objc private func toggleIsInvestment() {
        do {
            try transaction.setIsInvestment(state: !transaction.isInvestment)
        } catch {
            // present error
        }
    }
    
    @objc private func toggleIsUnread() {
        do {
            try transaction.setIsUnread(state: !transaction.isUnread)
        } catch {
            // present error
        }
    }
    
    @objc private func showExchangeValueActionSheet() {
        guard transaction.hasUserExchangeValue else {
            showExchangeValueInputAlert()
            return
        }
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Set exchange value", style: .default, handler: { _ in
            self.showExchangeValueInputAlert()
        }))
        
        if transaction.hasUserExchangeValue {
            alertController.addAction(UIAlertAction(title: "Reset exchange value", style: .destructive, handler: { _ in
                do {
                    try self.transaction.resetUserExchangeValue()
                } catch {
                    // present error
                }
            }))
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    private func showExchangeValueInputAlert() {
        let alertController = UIAlertController(title: "Exchange Value", message: nil, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { alertAction in
            let valueField = alertController.textFields![0]
            if let valueString = valueField.text?.trimmingCharacters(in: .whitespacesAndNewlines), let value = Double(valueString) {
                do {
                    try self.transaction.setUserExchangeValue(value: value)
                } catch {
                    // present error
                }
            }
        })
        
        saveAction.isEnabled = false
        valueSaveAction = saveAction
        
        alertController.addTextField(configurationHandler: { textField in
            textField.delegate = self
            textField.keyboardType = .decimalPad
            textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
            
            if let exchangeValue = self.transaction.exchangeValue {
                textField.placeholder = self.currencyFormatter.getCurrencyFormatting(for: exchangeValue, currency: self.transaction.owner!.quoteCurrency)
            } else {
                textField.placeholder = "???"
            }
        })
        
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        
        present(alertController, animated: true, completion: nil)
    }
   
    // MARK: - KryptonDaemon Delegate
    func kryptonDaemonDidUpdate(_ kryptonDaemon: KryptonDaemon) {
        updateUI()
    }
    
    // MARK: - TickerDaemon Delegate
    func tickerDaemon(_ tickerDaemon: TickerDaemon, didUpdateCurrentExchangeRateForCurrencyPair currencyPair: CurrencyPair) {
        updateUI()
    }
    
    // MARK: - BlockchainDaemon Delegate
    func blockchainDaemon(_ blockchainDaemon: BlockchainDaemon, didUpdateBlockCountForBlockchain blockchain: Blockchain) {
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
            case is Ethereum:
                return 3
            default:
                return 2
            }
        case _ where section == 2:
            return 2
        case _ where section == 3:
            return 3
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        
        switch section {
        case _ where section == 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionHeaderCell", for: indexPath) as! TransactionHeaderCell
            cell.configure(transaction: transaction, currencyFormatter: currencyFormatter, dateFormatter: dateFormatter)
            return cell
        case _ where section == 1:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "InfoCell")
            
            switch row {
            case _ where row == 0:
                sendersIndexPath = indexPath
                
                if transaction.senders.count > 1 {
                    cell.textLabel?.text = "Senders"
                    cell.detailTextLabel?.text = String(transaction.senders.count)
                    cell.accessoryType = .disclosureIndicator
                } else {
                    cell.textLabel?.text = "Sender"
                    cell.detailTextLabel?.text = portfolioManager.getAlias(for: transaction.primarySender)
                }
            case _ where row == 1:
                receiversIndexPath = indexPath
                
                
                if transaction.receivers.count > 1 {
                    cell.textLabel?.text = "Receivers"
                    cell.detailTextLabel?.text = String(transaction.receivers.count)
                    cell.accessoryType = .disclosureIndicator
                } else {
                    cell.textLabel?.text = "Receiver"
                    cell.detailTextLabel?.text = portfolioManager.getAlias(for: transaction.primaryReceiver)
                }
            case _ where row == 2 && transaction is EthereumTransaction:
                cell.textLabel?.text = "Type"
                cell.detailTextLabel?.text = (transaction as! EthereumTransaction).type
            default:
                break
            }
            
            return cell
        case _ where section == 2:
            switch row {
            case _ where row == 0:
                exchangeValueIndexPath = indexPath
                let cell = UITableViewCell(style: .value1, reuseIdentifier: "InfoCell")
                
                guard let exchangeValue = transaction.exchangeValue, let currentExchangeValue = transaction.currentExchangeValue else {
                    cell.textLabel?.text = "Value"
                    cell.detailTextLabel?.text = "???"
                    return cell
                }
                
                if showsExchangeValue {
                    cell.textLabel?.text = "Value"
                    cell.detailTextLabel?.text = currencyFormatter.getCurrencyFormatting(for: exchangeValue, currency: transaction.owner!.quoteCurrency)
                } else {
                    cell.textLabel?.text = "Current Value"
                    cell.detailTextLabel?.text = currencyFormatter.getCurrencyFormatting(for: currentExchangeValue, currency: transaction.owner!.quoteCurrency)
                }
                
                return cell
            case _ where row == 1:
                profitIndexPath = indexPath
                let cell = UITableViewCell(style: .value1, reuseIdentifier: "InfoCell")
                
                guard let profitStats = transaction.getProfitStats(timeframe: .allTime) else {
                    cell.textLabel?.text = "Profit"
                    cell.detailTextLabel?.text = "???"
                    return cell
                }
                
                if showsRelativeProfit {
                    cell.textLabel?.text = "Relative Profit"
                    cell.detailTextLabel?.text = currencyFormatter.getRelativeProfitFormatting(from: profitStats)
                } else {
                    cell.textLabel?.text = "Absolute Profit"
                    print(profitStats)
                    cell.detailTextLabel?.text = currencyFormatter.getAbsoluteProfitFormatting(from: profitStats, currency: transaction.owner!.quoteCurrency)
                }
                
                return cell
            default:
                // not valid
                return UITableViewCell()
            }
        case _ where section == 3:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "InfoCell")
            
            switch row {
            case _ where row == 0:
                feeIndexPath = indexPath
                cell.textLabel?.text = "Fee"
                
                if transaction.isOutbound && transaction.senders.count > 1 {
                    // fee was payed by muliple addresses
                    cell.accessoryType = .detailButton
                }
                
                guard let feeExchangeValue = transaction.feeExchangeValue else {
                    cell.detailTextLabel?.text = "???"
                    break
                }
                
                if showsCryptoFees {
                    cell.detailTextLabel?.text = currencyFormatter.getCurrencyFormatting(for: transaction.feeAmount, currency: transaction.owner!.blockchain)
                } else {
                    cell.detailTextLabel?.text = currencyFormatter.getCurrencyFormatting(for: feeExchangeValue, currency: transaction.owner!.quoteCurrency)
                }
            case _ where row == 1:
                blockIndexPath = indexPath
                
                guard let blockCount = blockchainDaemon.getBlockCount(for: transaction.owner!.blockchain) else {
                    cell.detailTextLabel?.text = "???"
                    break
                }
                
                if showsBlockNumber {
                    cell.textLabel?.text = "Block"
                    cell.detailTextLabel?.text = String(transaction.block)
                } else {
                    cell.textLabel?.text = "Confirmations"
                    cell.detailTextLabel?.text = String(blockCount-UInt64(transaction.block))
                }
            case _ where row == 2:
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
        case _ where indexPath == sendersIndexPath:
            guard let transaction = transaction as? BitcoinTransaction else {
                return
            }
        
            let amountByAddressViewController = viewFactory.makeAmountByAddressViewController(for: transaction)
            amountByAddressViewController.title = "Senders"
            amountByAddressViewController.addresses = transaction.senders
            amountByAddressViewController.amountForAddress = transaction.amountFromSender as! [String: Double]
            
            navigationController?.pushViewController(amountByAddressViewController, animated: true)
        case _ where indexPath == receiversIndexPath:
            guard let transaction = transaction as? BitcoinTransaction else {
                return
            }
            
            let amountByAddressViewController = viewFactory.makeAmountByAddressViewController(for: transaction)
            amountByAddressViewController.title = "Receivers"
            amountByAddressViewController.addresses = transaction.receivers
            amountByAddressViewController.amountForAddress = transaction.amountForReceiver as! [String: Double]
            
            navigationController?.pushViewController(amountByAddressViewController, animated: true)
        case _ where indexPath == exchangeValueIndexPath:
            showsExchangeValue = !showsExchangeValue
        case _ where indexPath == profitIndexPath:
            showsRelativeProfit = !showsRelativeProfit
        case _ where indexPath == feeIndexPath:
            showsCryptoFees = !showsCryptoFees
        case _ where indexPath == blockIndexPath:
            showsBlockNumber = !showsBlockNumber
        default:
            break
        }
        
        updateUI()
    }
    
    // MARK: - TextField Delegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let decimalSeperator = NumberFormatter().decimalSeparator!

        if string.count == 1 {
            if textField.text?.range(of: decimalSeperator) != nil {
                if string == decimalSeperator {
                    return false
                }
                
                if let subStrings = textField.text?.split(separator: Character(decimalSeperator)) {
                    let decimalDigits: String
                    
                    if subStrings.count == 2 {
                        decimalDigits = subStrings[1] + string
                    } else {
                        decimalDigits = string
                    }
                    
                    if decimalDigits.count > portfolioManager.quoteCurrency.decimalDigits {
                        return false
                    }
                }
                
                return true
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
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let newValueString = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !newValueString.isEmpty {
            valueSaveAction.isEnabled = true
        } else {
            valueSaveAction.isEnabled = false
        }
    }
    
}
