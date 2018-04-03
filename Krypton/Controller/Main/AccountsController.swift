//
//  AccountsController.swift
//  Krypton
//
//  Created by Niklas Sauer on 01.11.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class AccountsController: UITableViewController, PortfolioManagerDelegate, TickerDaemonDelegate {
    
    // MARK: - Private Properties
    private var portfolios = [Portfolio]()
    private var selectedAddresses: [Address]?
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(updatePortfolios), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
        
        PortfolioManager.shared.delegate = self
        TickerDaemon.delegate = self
        
        portfolios = PortfolioManager.shared.storedPortfolios.filter { $0.storedAddresses.count > 0 }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        do {
            _ = try PortfolioManager.shared.saveChanges()
        } catch {
            // present error
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destVC = segue.destination as? TransactionTableController {
            if selectedAddresses?.count == 1, let address = selectedAddresses?.first {
                destVC.addresses = [address]
                destVC.title = PortfolioManager.shared.getAlias(for: address.identifier!)
            } else {
                destVC.addresses = selectedAddresses
                destVC.title = "All Transactions"
            }
        }
        
        if let destVC = segue.destination as? AddressDetailController {
            guard selectedAddresses?.count == 1, let address = selectedAddresses?.first else {
                return
            }
            
            destVC.address = address
        }
    }
    
    // MARK: - Private Methods
    private func updateUI() {
        tableView.reloadSections(IndexSet(integer: 2), with: .automatic)
    }
    
    @objc private func updatePortfolios() {
        PortfolioManager.shared.update {
            self.refreshControl?.endRefreshing()
        }
    }
    
    // MARK: Collapse Helpers
    private func getHeaderIndices() -> [Int] {
        var index = 0
        var indices = [Int]()
        
        for portfolio in portfolios {
            indices.append(index)
            index = index + portfolio.storedAddresses.count + 1
        }
        
        return indices
    }
    
    private func getSectionIndex(_ row: Int) -> Int {
        let indices = getHeaderIndices()
        
        for i in 0..<indices.count {
            if i == indices.count - 1 || row < indices[i + 1] {
                return i
            }
        }
        
        return -1
    }
    
    private func getRowIndex(_ row: Int) -> Int {
        var index = row
        let indices = getHeaderIndices()
        
        for i in 0..<indices.count {
            if i == indices.count - 1 || row < indices[i + 1] {
                index -= indices[i]
                break
            }
        }
        
        return index
    }
    
    // MARK: - PortfolioManager Delegate
    func didUpdatePortfolioManager() {
        portfolios = PortfolioManager.shared.storedPortfolios.filter { $0.storedAddresses.count > 0 }
        updateUI()
    }
    
    // MARK: - TickerDaemon Delegate
    func didUpdateCurrentExchangeRate(for currencyPair: CurrencyPair) {
        updateUI()
    }
    
    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else if section == 1 {
            return 1
        } else {
            var count = portfolios.count
            
            for portfolio in portfolios {
                count = count + portfolio.storedAddresses.count
            }
            
            return count
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
            let section = getSectionIndex(indexPath.row)
            let row = getRowIndex(indexPath.row)
            
            if row == 0 {
                let portfolio = portfolios[section]
                let cell = tableView.dequeueReusableCell(withIdentifier: "portfolioHeaderCell", for: indexPath) as! SectionHeaderCell
                cell.isCollapsed = portfolio.isCollapsed
                cell.sectionTitleLabel.text = portfolio.alias?.uppercased()
                
                if let exchangeValue = portfolio.totalExchangeValue {
                    cell.rightDetailLabel.text = Format.getCurrencyFormatting(for: exchangeValue, currency: portfolio.quoteCurrency)
                } else {
                    cell.rightDetailLabel.text = nil
                }
                
                return cell
            } else {
                let address = portfolios[section].storedAddresses[row-1]
                let cell = tableView.dequeueReusableCell(withIdentifier: "accountCell", for: indexPath)
                cell.textLabel?.text = address.alias
                cell.detailTextLabel?.text = Format.getCurrencyFormatting(for: address.balance, currency: address.blockchain, customDigits: 2)
                return cell
            }
        }
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section == 2 else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
        
        let section = getSectionIndex(indexPath.row)
        let row = getRowIndex(indexPath.row)
        
        if row == 0 {
            // sectionHeader
            return super.tableView(tableView, heightForRowAt: indexPath)
        } else {
            // sectionItem
            return portfolios[section].isCollapsed ? 0 : 44
        }
    }
    
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
        } else if section == 2 {
            let section = getSectionIndex(indexPath.row)
            let row = getRowIndex(indexPath.row)
        
            if row == 0 {
                // toggle collapse
                portfolios[section].isCollapsed = !portfolios[section].isCollapsed
            
                let cell = tableView.cellForRow(at: indexPath) as! SectionHeaderCell
                cell.isCollapsed = portfolios[section].isCollapsed
                
                let indices = getHeaderIndices()
                
                let start = indices[section]
                let end = start + portfolios[section].storedAddresses.count
        
                tableView.beginUpdates()
                
                for i in start ..< end + 1 {
                    let indexPath = IndexPath(row: i, section: 2)
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                }
                
                tableView.endUpdates()
            } else {
                selectedAddresses = [portfolios[section].storedAddresses[row-1]]
                performSegue(withIdentifier: "showTransactions", sender: self)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard indexPath.section >= 2 else {
            return
        }
        
        let section = getSectionIndex(indexPath.row)
        let row = getRowIndex(indexPath.row)
        selectedAddresses = [portfolios[section].storedAddresses[row-1]]
        performSegue(withIdentifier: "showAddress", sender: self)
    }
    
}
