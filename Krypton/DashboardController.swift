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
    var showsPortfolioValue = true {
        didSet {
            guard let portfolioExchangeValue = PortfolioManager.shared.currentExchangeValue, let portfolioAbsoluteReturn = PortfolioManager.shared.absoluteReturn else {
                portfolioValueLabel.text = "???"
                return
            }
            
            if showsPortfolioValue {
                portfolioValueLabel.text = Format.fiatFormatter.string(from: NSNumber(value: portfolioExchangeValue))
                portfolioValueTypeLabel.text = "Portfolio Value"
            } else {
                portfolioValueLabel.text = Format.fiatFormatter.string(from: NSNumber(value: portfolioAbsoluteReturn))
                portfolioValueTypeLabel.text = "Total Absolute Increase"
            }
        }
    }
    
    // Mark: - Outlets
    @IBOutlet weak var portfolioValueLabel: UILabel!
    @IBOutlet weak var portfolioValueTypeLabel: UILabel!
    
    @IBOutlet weak var relativeReturnSinceLabel: UILabel!
    @IBOutlet weak var absoluteReturnSinceLabel: UILabel!

    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.delegate = self
        PortfolioManager.shared.delegate = self
        TickerWatchlist.delegate = self
        
        showsPortfolioValue = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleDashboard))
        portfolioValueLabel.isUserInteractionEnabled = true
        portfolioValueLabel.addGestureRecognizer(tapGestureRecognizer)
        portfolioValueLabel.tag = 0
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
    
    // MARK: - Private Methods
    private func updateUI() {
        guard let absoluteReturnHistory = PortfolioManager.shared.absoluteReturnHistory(since: comparisonDate), let absoluteReturnSince = absoluteReturnHistory.last?.value, let relativeReturnSince = PortfolioManager.shared.relativeReturn(since: comparisonDate) else {
            relativeReturnSinceLabel.text = "???"
            absoluteReturnSinceLabel.text = "???"
            portfolioValueLabel.text = "???"
            return
        }
        
        if showsPortfolioValue {
            showsPortfolioValue = true
        } else {
            showsPortfolioValue = false
        }
        
        relativeReturnSinceLabel.text = Format.numberFormatter.string(from: NSNumber(value: relativeReturnSince))! + "%"
        absoluteReturnSinceLabel.text = Format.fiatFormatter.string(from: NSNumber(value: absoluteReturnSince))
    }
    
    func toggleDashboard(sender: UITapGestureRecognizer) {
        guard let sender = sender.view else {
            return
        }
        
        switch sender.tag {
        case 0:
            showsPortfolioValue = !showsPortfolioValue
        default:
            return
        }
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
