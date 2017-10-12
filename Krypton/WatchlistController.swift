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
    var tradingPairs = [TradingPair]()
    
    // MARK: - Initialization
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        TickerWatchlist.delegate = self
        tradingPairs = Array(PortfolioManager.shared.storedTradingPairs)
    }

    // MARK: - TableView Delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tradingPairs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cryptoCurrency = tradingPairs[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "tickerCell", for: indexPath)
        cell.textLabel?.text = cryptoCurrency.rawValue
    
        let tradingPair = tradingPairs[indexPath.row]
        
        if let currentPrice = TickerWatchlist.getCurrentPrice(for: tradingPair) {
            cell.detailTextLabel?.text = Format.getCurrencyFormatting(for: currentPrice, currency: PortfolioManager.shared.baseCurrency)
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
