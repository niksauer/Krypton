//
//  WatchlistController.swift
//  Krypton
//
//  Created by Niklas Sauer on 30.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class WatchlistController: UITableViewController, TickerDaemonDelegate {
    
    // MARK: - Public Properties
    var displayedCurrencyPairs = Set<CurrencyPair>()
    var storedCurrencyPairs = Set<CurrencyPair>()
//    var allcurrencyPairs = [CurrencyPair]()

    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        TickerDaemon.delegate = self
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
//        for code in PortfolioManager.shared.storedCryptoCurrencyCodes {
//            guard let quoteCurrency = CurrencyManager.getCurrency(from: code) else {
//                continue
//            }
//            
//            storedCurrencyPairs.insert(CurrencyPair(base: quoteCurrency, quote: PortfolioManager.shared.quoteCurrency))
//        }
            
            
        displayedCurrencyPairs = storedCurrencyPairs
        
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedCurrencyPairs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currencyPair = Array(displayedCurrencyPairs)[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "tickerCell", for: indexPath)
        cell.textLabel?.text = currencyPair.base.code
    
        if let currentRate = currencyPair.currentRate {
            cell.detailTextLabel?.text = Format.getCurrencyFormatting(for: currentRate, currency: PortfolioManager.shared.quoteCurrency)
        } else {
            cell.detailTextLabel?.text = "???"
        }
        
        return cell
    }
    
    // MARK: - TickerDaemon Delegate
    func didUpdateCurrentPrice(for currencyPair: CurrencyPair) {
        tableView.reloadData()
    }

}
