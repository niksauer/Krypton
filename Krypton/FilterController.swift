//
//  FilterController.swift
//  Krypton
//
//  Created by Niklas Sauer on 15.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

@objc protocol FilterDelegate {
    @objc optional func didChangeHasUserExchangeValue(state: Bool)
    @objc optional func didChangeIsUnread(state: Bool)
    @objc optional func didChangeIsError(state: Bool)
    @objc optional func didChangeTransactionType(type: TransactionType)
    @objc optional func didChangeSelectedAddresses()
}

class FilterController: UITableViewController {
    
    // MARK: - Private Properties
    private let portfolios = PortfolioManager.shared.storedPortfolios.filter { $0.storedAddresses.count > 0 }
    private let filterSectionsCount = 2
    private let transactionTypeIndexPath = IndexPath(row: 0, section: 0)
    
    // MARK: - Public Properties
    var delegate: FilterDelegate?
    var isSelector = false
    
    var transactionType: TransactionType = .all
    var isError = false
    var isUnread = false
    var hasUserExchangeValue = false

    // MARK: - Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        PortfolioManager.shared.discardChanges()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func apply(_ sender: UIBarButtonItem) {
        delegate?.didChangeTransactionType?(type: transactionType)
        delegate?.didChangeIsUnread?(state: isUnread)
        delegate?.didChangeIsError?(state: isError)
        delegate?.didChangeHasUserExchangeValue?(state: hasUserExchangeValue)
        
        do {
            if try PortfolioManager.shared.saveChanges() {
                delegate?.didChangeSelectedAddresses?()
            } else {
                PortfolioManager.shared.discardChanges()
            }
        } catch {
            // present error
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Public Methods
    func setTransactionType(_ rawValue: Int) {
        transactionType = TransactionType(rawValue: rawValue) ?? transactionType
    }
    
    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        if isSelector {
            return filterSectionsCount + portfolios.count
        } else {
            return filterSectionsCount
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case _ where section == transactionTypeIndexPath.section:
            return 1
        case _ where section == 1:
            return 2
        default:
            return portfolios[section-filterSectionsCount].storedAddresses.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath {
        case _ where indexPath == transactionTypeIndexPath:
            let cell = tableView.dequeueReusableCell(withIdentifier: "segmentedControlCell", for: indexPath) as! SegmentedControlCell
            cell.configure(segments: ["All", "Investment", "Other"], selectedSegment: transactionType.rawValue, completion: setTransactionType)
            return cell
        case _ where indexPath.section == 1:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath) as! SwitchCell
                cell.configure(name: "Is Error", isOn: isError, completion: { state in
                    self.isError = state
                })
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath) as! SwitchCell
                cell.configure(name: "Manual Exchange Value", isOn: hasUserExchangeValue, completion: { state in
                    self.hasUserExchangeValue = state
                })
                return cell
            default:
                // invalid configuration
                return UITableViewCell()
            }
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
        case _ where section == 1:
            return "Properties"
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
