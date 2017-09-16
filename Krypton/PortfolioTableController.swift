//
//  PortfolioTableController.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class PortfolioTableController: UITableViewController {
    
    // MARK: - Public Properties
    var portfolio: Portfolio?
    var portfolios = PortfolioManager.shared.getPortfolios()
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - TableView Data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return portfolios.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "portfolioCell", for: indexPath)
        let portfolio = portfolios[indexPath.row]
        
        cell.textLabel?.text = portfolio.alias ?? "Portfolio \(indexPath.row + 1)"
        
        if portfolio.isDefault {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        portfolio = portfolios[indexPath.row]
        performSegue(withIdentifier: "undwindToAddAddressTable", sender: self)
    }

}
