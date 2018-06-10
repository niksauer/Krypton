//
//  AmountByAddressViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 25.10.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

enum AmountByAddressType {
    case sender
    case receiver
}

class AmountByAddressViewController: UITableViewController {
    
    // MARK: - Private Properties
    private let portfolioManager: PortfolioManager
    private let currencyFormatter: CurrencyFormatter
    private let addresses: [String]
    private let amountForAddress: [String: Double]
    private var currency: Currency
    
    // MARK: - Initialization
    init(transaction: BitcoinTransaction, portfolioManager: PortfolioManager, currencyFormatter: CurrencyFormatter, type: AmountByAddressType) {
        self.portfolioManager = portfolioManager
        self.currencyFormatter = currencyFormatter
        
        switch type {
        case .receiver:
            self.addresses = transaction.receivers
            self.amountForAddress = transaction.storedAmountForReceiver
        case .sender:
            self.addresses = transaction.senders
            self.amountForAddress = transaction.storedAmountFromSender
        }
        
        currency = transaction.owner!.blockchain
        
        super.init(style: .plain)
        
        switch type {
        case .receiver:
            title = "Receivers"
        case .sender:
            title = "Senders"
        }
        
        tableView.allowsSelection = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - TableView DataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return amountForAddress.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let address = addresses[indexPath.row]
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "InfoCell")
        
        cell.textLabel?.text = portfolioManager.getAlias(for: address)
        cell.detailTextLabel?.text = currencyFormatter.getCurrencyFormatting(for: amountForAddress[address]!, currency: currency)
        
        return cell
    }

}
