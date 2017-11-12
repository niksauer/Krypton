//
//  AmountForAddressController.swift
//  Krypton
//
//  Created by Niklas Sauer on 25.10.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class AmountForAddressController: UITableViewController {
    
    // MARK: - Public Properties
    var addresses: [String]!
    var amountForAddress: [String: Double]!
    var currency: CurrencyFeatures!

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
        
        cell.textLabel?.text = PortfolioManager.shared.getAlias(for: address)
        cell.detailTextLabel?.text = Format.getCurrencyFormatting(for: amountForAddress[address]!, currency: currency)
        
        return cell
    }

}
