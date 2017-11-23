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
    private var selectedAddresses: [Address]?
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(updateAddresses), for: .valueChanged)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        portfolios = PortfolioManager.shared.storedPortfolios.filter { $0.storedAddresses.count > 0 }
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destVC = segue.destination as? TransactionTableController {
            destVC.addresses = selectedAddresses
            
            if selectedAddresses?.count == 1 {
                destVC.title = PortfolioManager.shared.getAlias(for: selectedAddresses!.first!.identifier!)
            } else {
                destVC.title = "All Transactions"
            }
        }
        
        if let destVC = segue.destination as? AddressDetailController {
            destVC.address = selectedAddresses?.first
        }
    }
    
    // MARK: - Private Methods
    @objc private func updateAddresses() {
        PortfolioManager.shared.update {
            self.refreshControl?.endRefreshing()
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
            }
            if row == 1 {
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
            cell.textLabel?.text = address.alias
            cell.detailTextLabel?.text = Format.getCurrencyFormatting(for: address.balance, currency: address.blockchain, customDigits: 2)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section >= 2 else {
            return nil
        }
        
        return portfolios[section-2].alias
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        
        if section == 0 {
            if row == 0 {
                performSegue(withIdentifier: "showDashboard", sender: self)
            }
            if row == 1 {
                performSegue(withIdentifier: "showWatchlist", sender: self)
            }
        } else if section == 1 {
            if row == 0 {
                selectedAddresses = PortfolioManager.shared.storedAddresses
                performSegue(withIdentifier: "showTransactions", sender: self)
            }
        } else {
            selectedAddresses = [portfolios[section-2].storedAddresses[row]]
            performSegue(withIdentifier: "showTransactions", sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        
        guard section >= 2 else {
            return
        }
        
        selectedAddresses = [portfolios[section-2].storedAddresses[row]]
        performSegue(withIdentifier: "showAddress", sender: self)
    }
    
}
