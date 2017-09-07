//
//  DashboardController.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class DashboardController: UIViewController, UITabBarControllerDelegate, PortfolioManagerDelegate, TickerWatchlistDelegate {
    
    // MARK: - Properties
    var comparisonDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    
    // Mark: - Outlets
    @IBOutlet weak var portfolioValueLabel: UILabel!
    @IBOutlet weak var relativeReturnLabel: UILabel!
    @IBOutlet weak var absoluteReturnLabel: UILabel!
    @IBOutlet weak var currentRateLabel: UILabel!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.delegate = self
        PortfolioManager.shared.delegate = self
        TickerWatchlist.delegate = self
    }

    // MARK: - Navigation
    @IBAction func unwindToDashboard(segue: UIStoryboardSegue) {
        if let sourceVC = segue.source as? AddAddressController, let addressString = sourceVC.address, let unit = sourceVC.unit {
            do {
                try PortfolioManager.shared.addAddress(addressString, unit: unit)
            } catch {
                print(error)
            }
        }
    }
    
    @IBAction func deleteData(_ sender: UIBarButtonItem) {
        
    }
    
    // MARK: - Private Methods
    private func updateUI() {
        guard let absoluteReturnHistory = PortfolioManager.shared.absoluteReturnHistory(since: comparisonDate), let currentExchangeValue = PortfolioManager.shared.currentExchangeValue, let absoluteReturn = absoluteReturnHistory.last?.value, let relativeReturn = PortfolioManager.shared.relativeReturn(since: comparisonDate) else {
            portfolioValueLabel.text = "???"
            relativeReturnLabel.text = "???"
            absoluteReturnLabel.text = "???"
            currentRateLabel.text = "???"
            return
        }
        
        portfolioValueLabel.text = Format.fiatFormatter.string(from: NSNumber(value: currentExchangeValue))
        relativeReturnLabel.text = Format.numberFormatter.string(from: NSNumber(value: relativeReturn))! + "%"
        absoluteReturnLabel.text = Format.numberFormatter.string(from: NSNumber(value: absoluteReturn))
        currentRateLabel.text = Format.fiatFormatter.string(from: NSNumber(value: TickerWatchlist.currentPrice(for: Currency.tradingPair(cryptoCurrency: .ETH, fiatCurrency: .EUR)!)!))
    }
    
    // MARK: - TabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let destVC = viewController as? UINavigationController, let transactionVC = destVC.topViewController as? TransactionTableController {
            transactionVC.addresses = PortfolioManager.shared.selectedAddresses
        }
    }
    
    // MARK: - WalletDelegate
    func didUpdatePortfolioManager() {
        updateUI()
    }
    
    // MARK: - TickerWatchlistDelegate
    func didUpdateCurrentPrice(for tradingPair: Currency.TradingPair) {
        updateUI()
    }
    

}
