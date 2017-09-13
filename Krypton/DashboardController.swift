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
    enum PortfolioValueDisplayType {
        case currentExchangeValue
        case relativeProfit
        case absoluteProfit
    }
    
    var comparisonDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    
//    var portfolioValueDisplay: PortfolioValueDisplayType = .currentExchangeValue {
//        didSet {
//            switch self {
//            case .currentExchangeValue:
//                break
//            case .relativeProfit:
//                break
//            case .absoluteProfit:
//                break
//            }
//        }
//        
//    }

    var showsPortfolioValue = true {
        didSet {
            if showsPortfolioValue {
                portfolioLabel.text = "Total Portfolio Value"
            } else {
                portfolioLabel.text = "Total Absolute Profit"
            }
            
            guard let currentExchangeValue = PortfolioManager.shared.currentExchangeValue, let absoluteProfit = PortfolioManager.shared.absoluteProfit else {
                portfolioValueLabel.text = "???"
                return
            }
            
            if showsPortfolioValue {
                portfolioValueLabel.text = Format.fiatFormatter.string(from: NSNumber(value: currentExchangeValue))
            } else {
                portfolioValueLabel.text = Format.fiatFormatter.string(from: NSNumber(value: absoluteProfit))
            }
        }
    }
    
    var showsRelativeProfit = true {
        didSet {
            if showsRelativeProfit {
                profitLabel.text = "Relative Profit"
            } else {
                profitLabel.text = "Absolute Profit"
            }
            
            guard let relativeProfit = PortfolioManager.shared.relativeProfit(since: comparisonDate), let absoluteProfit = PortfolioManager.shared.absoluteProfit(since: comparisonDate) else {
                profitValueLabel.text = "???"
                return
            }
            
            if showsRelativeProfit {
                profitValueLabel.text = Format.numberFormatter.string(from: NSNumber(value: relativeProfit))! + "%"
            } else {
                profitValueLabel.text = Format.fiatFormatter.string(from: NSNumber(value: absoluteProfit))
            }
        }
    }
    
    // Mark: - Outlets
    @IBOutlet weak var portfolioValueLabel: UILabel!
    @IBOutlet weak var portfolioLabel: UILabel!
    
    @IBOutlet weak var profitValueLabel: UILabel!
    @IBOutlet weak var profitLabel: UILabel!
    
    @IBOutlet weak var investmentValueLabel: UILabel!
    @IBOutlet weak var investmentLabel: UILabel!
    

    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.delegate = self
        PortfolioManager.shared.delegate = self
        TickerWatchlist.delegate = self
        
        investmentLabel.text = "Total Investment"
        
        portfolioValueLabel.tag = 0
        portfolioValueLabel.isUserInteractionEnabled = true
        
        let portfolioValueTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(togglePortfolioValueType))
        portfolioValueLabel.addGestureRecognizer(portfolioValueTapRecognizer)
        
        profitValueLabel.tag = 1
        profitValueLabel.isUserInteractionEnabled = true
        
        let profitValueTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleReturnSinceValueType))
        profitValueLabel.addGestureRecognizer(profitValueTapRecognizer)
        
        showsPortfolioValue = true
        showsRelativeProfit = true
        
        if let investmentValue = PortfolioManager.shared.investmentValue {
            investmentValueLabel.text = Format.fiatFormatter.string(from: NSNumber(value: investmentValue))
        } else {
            investmentValueLabel.text = "???"
        }
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
        if showsPortfolioValue {
            showsPortfolioValue = true
        } else {
            showsPortfolioValue = false
        }
        
        if showsRelativeProfit {
            showsRelativeProfit = true
        } else {
            showsRelativeProfit = false
        }
        
        if let investmentValue = PortfolioManager.shared.investmentValue {
            investmentValueLabel.text = Format.fiatFormatter.string(from: NSNumber(value: investmentValue))
        } else {
            investmentValueLabel.text = "???"
        }
    }
    
    func toggleReturnSinceValueType(sender: UITapGestureRecognizer) {
        showsRelativeProfit = !showsRelativeProfit
    }
    
    func togglePortfolioValueType(sender: UITapGestureRecognizer) {
        showsPortfolioValue = !showsPortfolioValue
    }
    
    // MARK: - TabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let destVC = viewController as? UINavigationController, let transactionVC = destVC.topViewController as? TransactionTableController {
            transactionVC.addresses = PortfolioManager.shared.selectedAddresses
        }
    }
    
    // MARK: - PortfolioManagerDelegate
    func didUpdatePortfolioManager() {
        updateUI()
    }
    
    // MARK: - TickerWatchlistDelegate
    func didUpdateCurrentPrice(for tradingPair: Currency.TradingPair) {
        updateUI()
    }
    

}
