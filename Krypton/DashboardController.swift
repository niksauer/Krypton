//
//  DashboardController.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class DashboardController: UIViewController, UITabBarControllerDelegate, WalletDelegate, TickerWatchlistDelegate {
    
    // MARK: - Properties
    let wallet = Wallet()
    var comparisonDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    
    // Mark: - Outlets
    @IBOutlet weak var portfolioValueLabel: UILabel!
    @IBOutlet weak var relativeReturnLabel: UILabel!
    @IBOutlet weak var absoluteReturnLabel: UILabel!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.delegate = self
        wallet.delegate = self
        TickerWatchlist.delegate = self
    }

    // MARK: - Navigation
    @IBAction func unwindToDashboard(segue: UIStoryboardSegue) {
        if let sourceVC = segue.source as? AddAddressController, let addressString = sourceVC.address, let unit = sourceVC.unit {
            do {
                try wallet.addAddress(addressString, unit: unit)
            } catch {
                print(error)
            }
        }
    }
    
    @IBAction func deleteData(_ sender: UIBarButtonItem) {
        wallet.deleteCoreData()
    }
    
    // MARK: - Private Methods
    private func updateUI() {
        guard let currentExchangeValue = wallet.currentExchangeValue, let comparisonExchangeValue = wallet.exchangeValue(on: comparisonDate), let absoluteReturnHistory = wallet.absoluteReturnHistory(since: comparisonDate), let absoluteReturn = absoluteReturnHistory.last?.value else {
            portfolioValueLabel.text = "???"
            relativeReturnLabel.text = "???"
            absoluteReturnLabel.text = "???"
            return
        }
        
        let difference = currentExchangeValue - comparisonExchangeValue
        let relativeReturn = difference / comparisonExchangeValue * 100
        
        portfolioValueLabel.text = Format.fiatFormatter.string(from: NSNumber(value: currentExchangeValue))
        relativeReturnLabel.text = Format.numberFormatter.string(from: NSNumber(value: relativeReturn))! + "%"
        absoluteReturnLabel.text = Format.numberFormatter.string(from: NSNumber(value: absoluteReturn))
    }
    
    // MARK: - TabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let destVC = viewController as? UINavigationController, let transactionVC = destVC.topViewController as? TransactionTableController {
            transactionVC.addresses = wallet.addresses
        }
    }
    
    // MARK: - WalletDelegate
    func didUpdateWallet(_ wallet: Wallet) {
        updateUI()
    }
    
    // MARK: - TickerWatchlistDelegate
    func didUpdateCurrentPrice(for tradingPair: Currency.TradingPair) {
        updateUI()
    }
}
