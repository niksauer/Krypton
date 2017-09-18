//
//  FilterController.swift
//  Krypton
//
//  Created by Niklas Sauer on 15.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class FilterController: UITableViewController {
    
    // MARK: - Public Properties
    var delegate: FilterDelegate?
    var transactionType: TransactionType?
    
    // MARK: - Private Properties
    private let filterOptionsCount = 1
    private let portfolios = PortfolioManager.shared.getPortfolios()
    private var newTransactionType: TransactionType?

    // MARK: - Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func apply(_ sender: UIBarButtonItem) {
        if newTransactionType != nil, newTransactionType != transactionType {
            delegate?.didChangeTransactionType(to: newTransactionType!)
        }
        
        do {
            if try PortfolioManager.shared.save() {
                delegate?.didChangeSelectedAddresses()
            }
        } catch {
            print(error)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Public Methods
    @IBAction func setTransactionType(_ sender: UISegmentedControl) {
        newTransactionType = TransactionType(rawValue: sender.selectedSegmentIndex)!
    }
    
    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return portfolios.count + filterOptionsCount
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return portfolios[section-filterOptionsCount].storedAddresses.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "transactionTypeCell", for: indexPath)
            let transactionTypeSwitch = cell.contentView.subviews.first as! UISegmentedControl
    
            if let type = transactionType {
                transactionTypeSwitch.selectedSegmentIndex = type.rawValue
            } else {
                transactionTypeSwitch.selectedSegmentIndex = 0
            }
            
            return cell
        } else {
            let address = portfolios[indexPath.section-filterOptionsCount].storedAddresses[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "addressCell", for: indexPath)
            cell.textLabel?.text = address.address
            cell.detailTextLabel?.text = address.alias
        
            if address.isSelected {
                cell.accessoryType = .checkmark
            }
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section != 0 else {
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        
        let address = portfolios[indexPath.section-filterOptionsCount].storedAddresses[indexPath.row]
        
        if cell.accessoryType == .checkmark {
            cell.accessoryType = .none
            address.isSelected = false
        } else {
            cell.accessoryType = .checkmark
            address.isSelected = true
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section != 0 else {
            return "Transaction Type"
        }
        
        let portfolio = portfolios[section-filterOptionsCount]
        
        if let portfolioAlias = portfolio.alias {
            return portfolioAlias
        } else {
            return "Portfolio \(section-filterOptionsCount + 1)"
        }
    }

}

// MARK: - Filter Delegate Protocol
protocol FilterDelegate {
    func didChangeSelectedAddresses()
    func didChangeTransactionType(to type: TransactionType)
}
