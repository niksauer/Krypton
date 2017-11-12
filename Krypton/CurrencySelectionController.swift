//
//  CurrencySelectionController.swift
//  Krypton
//
//  Created by Niklas Sauer on 17.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

protocol CurrencySelectionDelegate {
    func didSelectCurrency(selection: CurrencyFeatures)
}

class CurrencySelectionController: UITableViewController {

    // MARK: - Private Properties
    private var currencies: [CurrencyFeatures]!
    
    // MARK: - Public Properties
    var delegate: CurrencySelectionDelegate?
    var selection: CurrencyFeatures?
    var type: CurrencyType!
    var exceptions = [CurrencyFeatures]()
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        currencies = CurrencyManager.getCurrencies(of: type)
    }

    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currencies.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "currencyCell", for: indexPath)
        let currency = currencies[indexPath.row]
        cell.textLabel?.text = currency.code
        
        if currency.code == selection?.code {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currency = currencies[indexPath.row]
        delegate?.didSelectCurrency(selection: currency)
        self.navigationController?.popViewController(animated: true)
    }
    
}
