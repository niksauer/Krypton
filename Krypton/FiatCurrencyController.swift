//
//  FiatCurrencyController.swift
//  Krypton
//
//  Created by Niklas Sauer on 17.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class FiatCurrencyController: UITableViewController {

    // MARK: - Public Properties
    var delegate: FiatCurrencyDelegate?
    var selection: Currency.Fiat = .EUR
    var fiatCurrencies = Currency.Fiat.allValues
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fiatCurrencies.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fiatCurrencyCell", for: indexPath)
        let currency = fiatCurrencies[indexPath.row]
        cell.textLabel?.text = currency.rawValue
        
        if currency == selection {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currency = fiatCurrencies[indexPath.row]
        selection = currency
        delegate?.didSelectFiatCurrency(selection: selection)
        self.navigationController?.popViewController(animated: true)
    }
    
}

protocol FiatCurrencyDelegate {
    func didSelectFiatCurrency(selection: Currency.Fiat)
}
