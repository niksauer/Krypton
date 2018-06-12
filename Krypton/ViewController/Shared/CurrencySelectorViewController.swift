//
//  CurrencySelectorViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 17.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

protocol CurrencySelectorDelegate {
    func currencySelector(_ currencySelector: CurrencySelectorViewController, didChangeSelectedCurrency currency: Currency)
}

class CurrencySelectorViewController: UITableViewController {
    
    // MARK: - Private Properties
    private let type: CurrencyType
    private var selection: Currency?
    private let currencyManager: CurrencyManager
    private let currencies: [Currency]
    
    // MARK: - Public Properties
    var delegate: CurrencySelectorDelegate?
    
    // MARK: - Initialization
    init(type: CurrencyType, selection: Currency?, currencyManager: CurrencyManager) {
        self.type = type
        self.selection = selection
        self.currencyManager = currencyManager
        currencies = currencyManager.getCurrencies(type: type)
        
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - TableView DataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currencies.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "CurrencyCell")
        let currency = currencies[indexPath.row]
        cell.textLabel?.text = currency.code
        
        if let selection = selection, currency.isEqual(to: selection) {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currency = currencies[indexPath.row]
        delegate?.currencySelector(self, didChangeSelectedCurrency: currency)
        self.navigationController?.popViewController(animated: true)
    }
    
}
