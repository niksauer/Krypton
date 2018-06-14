//
//  FilterController.swift
//  Krypton
//
//  Created by Niklas Sauer on 15.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit
import ToolKit

@objc protocol FilterDelegate {
    @objc optional func filterControllerDidSetSelectedAddresses(_ filterController: FilterViewController)
    @objc optional func filterControllerDidResetFilter(_ filterController: FilterViewController)
    
    @objc optional func filterController(_ filterController: FilterViewController, didSetHasUserExchangeValue hasUserExchangeValue: Bool)
    @objc optional func filterController(_ filterController: FilterViewController, didSetIsUnread isUnread: Bool)
    @objc optional func filterController(_ filterController: FilterViewController, didSetIsError isError: Bool)
    @objc optional func filterController(_ filterController: FilterViewController, didSetTransactionType type: TransactionType)
}

class FilterViewController: UITableViewController {
    
    // MARK: - Private Properties
    private let portfolioManager: PortfolioManager
    private let portfolios: [Portfolio]
    private let showsAdvancedProperties: Bool
    private let filterSectionsCount: Int
    private var isSelector: Bool
    
    // MARK: - Public Properties
    var delegate: FilterDelegate?
    var filter = Filter()

    // MARK: - Initialization
    init(portfolioManager: PortfolioManager, showsAdvancedProperties: Bool, isSelector: Bool) {
        self.portfolioManager = portfolioManager
        self.portfolios = portfolioManager.storedPortfolios.filter { $0.storedAddresses.count > 0 }
        
        self.showsAdvancedProperties = showsAdvancedProperties
        
        if showsAdvancedProperties {
            filterSectionsCount = 2
        } else {
            filterSectionsCount = 1
        }
        
        self.isSelector = isSelector
        
        super.init(style: .grouped)
        
        title = "Filter"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Apply", style: .done, target: self, action: #selector(applyButtonPressed))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(SegmentedControlCell.self, forCellReuseIdentifier: "SegmentedControlCell")
        tableView.register(SwitchCell.self, forCellReuseIdentifier: "SwitchCell")
    }
    
    // MARK: - Public Methods
    @objc private func cancelButtonPressed() {
        portfolioManager.discardChanges()
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func applyButtonPressed() {
        delegate?.filterController?(self, didSetTransactionType: filter.transactionType)
        delegate?.filterController?(self, didSetIsUnread: filter.isUnread)
        delegate?.filterController?(self, didSetIsError: filter.isError)
        delegate?.filterController?(self, didSetHasUserExchangeValue: filter.hasUserExchangeValue)
        
        do {
            if try portfolioManager.saveChanges() {
                delegate?.filterControllerDidSetSelectedAddresses?(self)
            } else {
                portfolioManager.discardChanges()
            }
        } catch {
            displayAlert(title: "Error", message: "Failed to save selected addresses: \(error)", completion: nil)
        }
        
        if !filter.isApplied {
            delegate?.filterControllerDidResetFilter?(self)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func didChangeTransactionType(_ sender: UISegmentedControl) {
        filter.transactionType = TransactionType(rawValue: sender.selectedSegmentIndex)!
    }
    
    @objc private func didChangeIsError(_ sender: UISwitch) {
        filter.isError = sender.isOn
    }
    
    @objc private func didChangeHasUserExchangeValue(_ sender: UISwitch) {
        filter.hasUserExchangeValue = sender.isOn
    }
    
    @objc private func didChangeIsUnread(_ sender: UISwitch) {
        filter.isUnread = sender.isOn
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
        case _ where section == 0:
            return 1
        case _ where section == 1 && showsAdvancedProperties:
            return 3
        default:
            return portfolios[section-filterSectionsCount].storedAddresses.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        
        switch section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SegmentedControlCell", for: indexPath) as! SegmentedControlCell
            cell.setup(segments: ["All", "Investment", "Other"], selectedSegment: filter.transactionType.rawValue)
            cell.segmentedControl.addTarget(self, action: #selector(didChangeTransactionType(_:)), for: .valueChanged)
            return cell
        case 1 where showsAdvancedProperties:
            switch row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
                cell.label.text = "Is Error"
                cell.switchControl.isOn = filter.isError
                cell.switchControl.addTarget(self, action: #selector(didChangeIsError(_:)), for: .valueChanged)
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
                cell.label.text = "Manual Exchange Value"
                cell.switchControl.isOn = filter.hasUserExchangeValue
                cell.switchControl.addTarget(self, action: #selector(didChangeHasUserExchangeValue(_:)), for: .valueChanged)
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
                cell.label.text = "Unread"
                cell.switchControl.isOn = filter.isUnread
                cell.switchControl.addTarget(self, action: #selector(didChangeIsUnread(_:)), for: .valueChanged)
                return cell
            default:
                // invalid configuration
                return UITableViewCell()
            }
        default:
            let address = portfolios[indexPath.section-filterSectionsCount].storedAddresses[indexPath.row]
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "AddressCell")
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
        case 0:
            return "Transaction Type"
        case 1 where showsAdvancedProperties:
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
