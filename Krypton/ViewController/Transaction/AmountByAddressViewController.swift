//
//  AmountForAddressController.swift
//  Krypton
//
//  Created by Niklas Sauer on 25.10.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

class AmountByAddressViewController: UITableViewController {
    
    // MARK: - Private Properties
    private let portfolioManager: PortfolioManager
    
    // MARK: - Public Properties
    var addresses: [String]!
    var amountForAddress: [String: Double]!
    var currency: Currency
    var currencyFormatter: CurrencyFormatter

    // MARK: - Initialization
    init(transaction: Transaction, portfolioManager: PortfolioManager, currencyFormatter: CurrencyFormatter) {
        self.portfolioManager = portfolioManager
        self.currencyFormatter = currencyFormatter
        currency = transaction.owner!.blockchain
        
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return amountForAddress.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath)
        let address = addresses[indexPath.row]
        
        cell.textLabel?.numberOfLines = 1;
        cell.textLabel?.lineBreakMode = .byTruncatingTail
        
        cell.textLabel?.text = portfolioManager.getAlias(for: address)
        cell.detailTextLabel?.text = currencyFormatter.getCurrencyFormatting(for: amountForAddress[address]!, currency: currency)
        
        return cell
    }

}
