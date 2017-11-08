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
    @objc optional func didResetFilterOptions()
}

struct FilterOptions {
    var transactionType: TransactionType
    var isUnread: Bool
    var isError: Bool
    var hasUserExchangeValue: Bool
    
    private static var nameForProperty: [String : String] = [
        "transactionType" : "Type",
        "hasUserExchangeValue" : "Manual Value",
        "isUnread" : "Unread",
        "isError" : "Error"
    ]

    private func allProperties() -> [String: Any] {
        var result: [String: Any] = [:]

        let mirror = Mirror(reflecting: self)
        
        for (labelMaybe, valueMaybe) in mirror.children {
            guard let label = labelMaybe else {
                continue
            }
            
            result[label] = valueMaybe
        }
        
        return result
    }

    var hasAppliedFilter: Bool {
        return transactionType != .all || isUnread || isError || hasUserExchangeValue
    }

    var appliedFiltersDescription: String {
        var activeProperties: [String] = []

        for property in allProperties() {
            if let isActive = property.value as? Bool, isActive {
                activeProperties.append(FilterOptions.nameForProperty[property.key]!)
            }

            if let type = property.value as? TransactionType, type != .all {
                activeProperties.append(FilterOptions.nameForProperty[property.key]!)
            }
        }

        return activeProperties.joined(separator: ", ")
    }
}

class FilterController: UITableViewController {
    
    // MARK: - Private Properties
    private let portfolios = PortfolioManager.shared.storedPortfolios.filter { $0.storedAddresses.count > 0 }
    private let filterSectionsCount = 2
    private let transactionTypeIndexPath = IndexPath(row: 0, section: 0)
    
    // MARK: - Public Properties
    var delegate: FilterDelegate?
    var isSelector = false
    
    var options = FilterOptions(transactionType: .all, isUnread: false, isError: false, hasUserExchangeValue: false)

    // MARK: - Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        PortfolioManager.shared.discardChanges()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func apply(_ sender: UIBarButtonItem) {
        guard options.hasAppliedFilter else {
            delegate?.didResetFilterOptions?()
            dismiss(animated: true, completion: nil)
            return
        }
        
        delegate?.didChangeTransactionType?(type: options.transactionType)
        delegate?.didChangeIsUnread?(state: options.isUnread)
        delegate?.didChangeIsError?(state: options.isError)
        delegate?.didChangeHasUserExchangeValue?(state: options.hasUserExchangeValue)
        
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
        options.transactionType = TransactionType(rawValue: rawValue)!
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
            return 3
        default:
            return portfolios[section-filterSectionsCount].storedAddresses.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath {
        case _ where indexPath == transactionTypeIndexPath:
            let cell = tableView.dequeueReusableCell(withIdentifier: "segmentedControlCell", for: indexPath) as! SegmentedControlCell
            cell.configure(segments: ["All", "Investment", "Other"], selectedSegment: options.transactionType.rawValue, completion: setTransactionType)
            return cell
        case _ where indexPath.section == 1:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath) as! SwitchCell
                cell.configure(name: "Is Error", isOn: options.isError, completion: { state in
                    self.options.isError = state
                })
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath) as! SwitchCell
                cell.configure(name: "Manual Exchange Value", isOn: options.hasUserExchangeValue, completion: { state in
                    self.options.hasUserExchangeValue = state
                })
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath) as! SwitchCell
                cell.configure(name: "Unread", isOn: options.isUnread, completion: { state in
                    self.options.isUnread = state
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
