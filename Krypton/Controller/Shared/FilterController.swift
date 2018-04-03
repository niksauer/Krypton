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
    @objc optional func didResetFilter()
}

struct Filter {
    
    // MARK: - Private Properties
    private static var displayNameForOption: [String : String] = [
        "transactionType" : "Type",
        "hasUserExchangeValue" : "Manual Value",
        "isUnread" : "Unread",
        "isError" : "Error"
    ]
    
    // MARK: - Public Properties
    var transactionType: TransactionType
    var isUnread: Bool
    var isError: Bool
    var hasUserExchangeValue: Bool
    
    var isApplied: Bool {
        return transactionType != .all || isUnread || isError || hasUserExchangeValue
    }
    
    var description: String {
        var activeProperties: [String] = []
        
        for option in allProperties() {
            if let isActive = option.value as? Bool, isActive {
                activeProperties.append(Filter.displayNameForOption[option.key]!)
            }
            
            if let type = option.value as? TransactionType, type != .all {
                activeProperties.append(Filter.displayNameForOption[option.key]!)
            }
        }
        
        return activeProperties.joined(separator: ", ")
    }

    // MARK: - Initialization
    init() {
        self.transactionType = .all
        self.isUnread = true
        self.isError = false
        self.hasUserExchangeValue = false
    }
    
    // MARK: - Private Methods
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
    
}

class FilterController: UITableViewController {
    
    // MARK: - Private Properties
    private let portfolios = PortfolioManager.shared.storedPortfolios.filter { $0.storedAddresses.count > 0 }
    private var filterSectionsCount = 2
    private let transactionTypeIndexPath = IndexPath(row: 0, section: 0)
    
    // MARK: - Public Properties
    var delegate: FilterDelegate?
    var isSelector = false
    var showsAdvancedProperties = false
    
    var filter = Filter()

    // MARK: - Initialization
    override func viewDidLoad() {
        if showsAdvancedProperties {
            filterSectionsCount = 2
        } else {
            filterSectionsCount = 1
        }
    }
    
    // MARK: - Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        PortfolioManager.shared.discardChanges()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func apply(_ sender: UIBarButtonItem) {
        delegate?.didChangeTransactionType?(type: filter.transactionType)
        delegate?.didChangeIsUnread?(state: filter.isUnread)
        delegate?.didChangeIsError?(state: filter.isError)
        delegate?.didChangeHasUserExchangeValue?(state: filter.hasUserExchangeValue)
        
        do {
            if try PortfolioManager.shared.saveChanges() {
                delegate?.didChangeSelectedAddresses?()
            } else {
                PortfolioManager.shared.discardChanges()
            }
        } catch {
            // present error
        }
        
        if !filter.isApplied {
            delegate?.didResetFilter?()
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Public Methods
    func setTransactionType(_ rawValue: Int) {
        filter.transactionType = TransactionType(rawValue: rawValue)!
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
        case _ where section == 1 && showsAdvancedProperties:
            return 3
        default:
            return portfolios[section-filterSectionsCount].storedAddresses.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath {
        case _ where indexPath == transactionTypeIndexPath:
            let cell = tableView.dequeueReusableCell(withIdentifier: "segmentedControlCell", for: indexPath) as! SegmentedControlCell
            cell.configure(segments: ["All", "Investment", "Other"], selectedSegment: filter.transactionType.rawValue, completion: setTransactionType)
            return cell
        case _ where indexPath.section == 1 && showsAdvancedProperties:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath) as! SwitchCell
                cell.configure(name: "Is Error", isOn: filter.isError, completion: { state in
                    self.filter.isError = state
                })
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath) as! SwitchCell
                cell.configure(name: "Manual Exchange Value", isOn: filter.hasUserExchangeValue, completion: { state in
                    self.filter.hasUserExchangeValue = state
                })
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath) as! SwitchCell
                cell.configure(name: "Unread", isOn: filter.isUnread, completion: { state in
                    self.filter.isUnread = state
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
        case _ where section == 1 && showsAdvancedProperties:
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
