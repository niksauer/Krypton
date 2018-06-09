//
//  FilterController.swift
//  Krypton
//
//  Created by Niklas Sauer on 15.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

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
        
        tableView.register(UINib(nibName: "SegmentedControlCell", bundle: nil), forCellReuseIdentifier: "SegmentedControlCell")
        tableView.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: "SwitchCell")
    }
    
    // MARK: - Public Methods
    @IBAction func cancelButtonPressed() {
        portfolioManager.discardChanges()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func applyButtonPressed() {
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
            // TODO: present error
        }
        
        if !filter.isApplied {
            delegate?.filterControllerDidResetFilter?(self)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
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
            cell.configure(segments: ["All", "Investment", "Other"], selectedSegment: filter.transactionType.rawValue, onChange: setTransactionType)
            return cell
        case 1 where showsAdvancedProperties:
            switch row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
                cell.configure(name: "Is Error", isOn: filter.isError, onChange: { state in
                    self.filter.isError = state
                })
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
                cell.configure(name: "Manual Exchange Value", isOn: filter.hasUserExchangeValue, onChange: { state in
                    self.filter.hasUserExchangeValue = state
                })
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
                cell.configure(name: "Unread", isOn: filter.isUnread, onChange: { state in
                    self.filter.isUnread = state
                })
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
