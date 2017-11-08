//
//  AccountsController.swift
//  Krypton
//
//  Created by Niklas Sauer on 01.11.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class AccountsController: UITableViewController {

    // MARK: - Private Properties
    private var portfolios = PortfolioManager.shared.storedPortfolios.filter { $0.storedAddresses.count > 0 }
    
    // MARK: - Initialization
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        portfolios = PortfolioManager.shared.storedPortfolios.filter { $0.storedAddresses.count > 0 }
        tableView.reloadData()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let indexPath = tableView.indexPathForSelectedRow else {
            return
        }
        
        let section = indexPath.section
        let row = indexPath.row
        
        if let destVC = segue.destination as? TransactionTableController {
            if section == 1 {
                if row == 0 {
                    destVC.addresses = PortfolioManager.shared.storedAddresses
                    destVC.title = "All Transactions"
                }
            } else if section > 1 {
                let address = portfolios[section-2].storedAddresses[row]
                destVC.addresses = [address]
                destVC.title = PortfolioManager.shared.getAlias(for: address.identifier!)
            }
        }
    }
    
    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2 + portfolios.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else if section == 1 {
            return 1
        } else {
            return portfolios[section-2].storedAddresses.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        
        if section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath)
            
            if row == 0 {
                cell.textLabel?.text = "Dashboard"
            } else if row == 1 {
                cell.textLabel?.text = "Watchlist"
            }
            
            return cell
        } else if section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath)
            cell.textLabel?.text = "All Transactions"
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "accountCell", for: indexPath)
            
            let portfolio = portfolios[section-2]
            let address = portfolio.storedAddresses[row]
            
            cell.textLabel?.text = address.identifier
            cell.detailTextLabel?.text = address.alias
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section > 1 {
            return portfolios[section-2].alias
        } else {
            return nil
        }
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        
        if section == 0 {
            if row == 0 {
                performSegue(withIdentifier: "showDashboard", sender: self)
            } else if row == 1 {
                performSegue(withIdentifier: "showWatchlist", sender: self)
            }
        } else if section == 1 {
            if row == 0 {
                performSegue(withIdentifier: "showTransactions", sender: self)
            }
        } else {
            performSegue(withIdentifier: "showTransactions", sender: self)
        }
    }
    
}
