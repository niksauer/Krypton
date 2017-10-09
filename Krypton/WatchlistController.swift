//
//  WatchlistController.swift
//  Krypton
//
//  Created by Niklas Sauer on 30.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class WatchlistController: UITableViewController, TickerWatchlistDelegate {
    
    // MARK: - Public Properties
    var cryptoCurrencies = [Blockchain]()
    
    // MARK: - Initialization
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        TickerWatchlist.delegate = self
        
        if let stored = PortfolioManager.shared.storedCryptoCurrencies {
            cryptoCurrencies = stored
        } else {
            cryptoCurrencies = []
        }
    }

    // MARK: - TableView Delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cryptoCurrencies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cryptoCurrency = cryptoCurrencies[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "tickerCell", for: indexPath)
        cell.textLabel?.text = cryptoCurrency.rawValue
        
        let baseCurrency = PortfolioManager.shared.baseCurrency
        let tradingPair = TradingPair.getTradingPair(a: cryptoCurrency, b: baseCurrency)!
        
        if let currentPrice = TickerWatchlist.getCurrentPrice(for: tradingPair) {
            cell.detailTextLabel?.text = Format.getFiatFormatting(for: NSNumber(value: currentPrice), fiatCurrency: baseCurrency)
        } else {
            cell.detailTextLabel?.text = "???"
        }
        
        return cell
    }
    
    // MARK: - TickerWatchlist Delegate
    func didUpdateCurrentPrice(for tradingPair: TradingPair) {
        tableView.reloadData()
    }

}
