//
//  WatchlistController.swift
//  Krypton
//
//  Created by Niklas Sauer on 30.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class WatchlistController: UITableViewController, TickerWatchlistDelegate, CurrencySelectionDelegate {
    
    // MARK: - Public Properties
    var tradingPairs = [TradingPair]()
    
    // MARK: - Initialization
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        TickerWatchlist.delegate = self
        tradingPairs = Array(PortfolioManager.shared.storedTradingPairs)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destVC = segue.destination as? CurrencySelectionController {
            destVC.delegate = self
            destVC.selection = PortfolioManager.shared.baseCurrency
            destVC.type = .crypto
            destVC.title = "Crypto Currency"
//            destVC.exceptions = PortfolioManager.shared.storedCryptoCurrencies
        }
    }
    
    // MARK: - TableView Data Source
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

    // MARK: - CurrencySelector Delegate
    func didSelectCurrency(selection: Currency) {
        
    }
}
