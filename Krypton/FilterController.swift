//
//  FilterController.swift
//  Krypton
//
//  Created by Niklas Sauer on 15.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

protocol FilterDelegate {
    func didChangeSelectedAddresses()
    func didChangeTransactionType(to type: TransactionType)
}

class FilterController: UITableViewController {
    
    // MARK: - Public Properties
    var delegate: FilterDelegate?
    var selectedTransactionType: TransactionType?
    
    // MARK: - Private Properties
    private let portfolios = PortfolioManager.shared.storedPortfolios.filter { $0.storedAddresses.count > 0 }
    private let filterSectionsCount = 1
    private let transactionTypeIndexPath = IndexPath(row: 0, section: 0)
    private var newSelectedTransactionType: TransactionType?

    // MARK: - Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func apply(_ sender: UIBarButtonItem) {
        if newSelectedTransactionType != nil, newSelectedTransactionType != selectedTransactionType {
            delegate?.didChangeTransactionType(to: newSelectedTransactionType!)
        }
        
        do {
            if try PortfolioManager.shared.save() {
                delegate?.didChangeSelectedAddresses()
            }
        } catch {
            // present error
            print(error)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Public Methods
    @IBAction func setTransactionType(_ sender: UISegmentedControl) {
        newSelectedTransactionType = TransactionType(rawValue: sender.selectedSegmentIndex)!
    }
    
    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return filterSectionsCount + portfolios.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case _ where section == transactionTypeIndexPath.section:
            return 1
        default:
            return portfolios[section-filterSectionsCount].storedAddresses.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath {
        case _ where indexPath == transactionTypeIndexPath:
            let cell = tableView.dequeueReusableCell(withIdentifier: "transactionTypeCell", for: indexPath)
            let transactionTypeSwitch = cell.contentView.subviews.first as! UISegmentedControl
            
            if selectedTransactionType != nil {
                transactionTypeSwitch.selectedSegmentIndex = selectedTransactionType!.rawValue
            } else {
                transactionTypeSwitch.selectedSegmentIndex = TransactionType.all.rawValue
            }
            
            return cell
        default:
            let address = portfolios[indexPath.section-filterSectionsCount].storedAddresses[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "addressCell", for: indexPath)
            cell.textLabel?.text = address.identifier
            cell.detailTextLabel?.text = address.alias
            
            if address.isSelected {
                cell.accessoryType = .checkmark
            }
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case _ where section == transactionTypeIndexPath.section:
            return "Transaction Type"
        default:
            let portfolio = portfolios[section-filterSectionsCount]
            return portfolio.alias!
        }
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section > filterSectionsCount-1 else {
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        
        let address = portfolios[indexPath.section-filterSectionsCount].storedAddresses[indexPath.row]
        
        if cell.accessoryType == .checkmark {
            cell.accessoryType = .none
            address.isSelected = false
        } else {
            cell.accessoryType = .checkmark
            address.isSelected = true
        }
    }
    
}


