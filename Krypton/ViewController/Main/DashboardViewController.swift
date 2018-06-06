//
//  DashboardController.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

class DashboardViewController: UIViewController, KryptonDaemonDelegate, TickerDaemonDelegate, FilterDelegate {

    // Mark: - Outlets
    @IBOutlet weak var portfolioValueLabel: UILabel!
    @IBOutlet weak var portfolioLabel: UILabel!
    @IBOutlet weak var profitValueLabel: UILabel!
    @IBOutlet weak var profitLabel: UILabel!
    @IBOutlet weak var investmentValueLabel: UILabel!
    @IBOutlet weak var investmentLabel: UILabel!
    
    // MARK: - Private Types
    private enum PortfolioDisplayType {
        case currentExchangeValue
        case relativeProfit
        case absoluteProfit
    }
    
    // MARK: - Private Properties
    private let viewFactory: ViewControllerFactory
    private let kryptonDaemon: KryptonDaemon
    private let portfolioManager: PortfolioManager
    private let tickerDaemon: TickerDaemon

    private var comparisonDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())! {
        didSet {
            updateUI()
        }
    }
    
    private var filter = Filter() {
        didSet {
            updateUI()
        }
    }
    
    private var portfolioDisplay: PortfolioDisplayType = .currentExchangeValue {
        didSet {
            guard let currentExchangeValue = portfolioManager.getExchangeValue(for: filter.transactionType, on: Date()), let profitStats = portfolioManager.getProfitStats(for: filter.transactionType, timeframe: .allTime) else {
                portfolioValueLabel.text = "???"
                return
            }
            
            switch portfolioDisplay {
            case .currentExchangeValue:
                portfolioLabel.text = "Total Portfolio Value"
                portfolioValueLabel.text = Format.getCurrencyFormatting(for: currentExchangeValue, currency: portfolioManager.quoteCurrency)
            case .relativeProfit:
                portfolioLabel.text = "Total Relative Profit"
                portfolioValueLabel.text = Format.getRelativeProfitFormatting(from: profitStats)
            case .absoluteProfit:
                portfolioLabel.text = "Total Absolute Profit"
                portfolioValueLabel.text = Format.getAbsoluteProfitFormatting(from: profitStats, currency: portfolioManager.quoteCurrency)
            }
        }
    }
    
    private var showsRelativeProfit: Bool = true {
        didSet {
            guard let profitStats = portfolioManager.getProfitStats(for: filter.transactionType, timeframe: .sinceDate(comparisonDate)) else {
                profitValueLabel.text = "???"
                return
            }

            profitLabel.text = "Since Yesterday"
            
            if showsRelativeProfit {
                profitValueLabel.text = Format.getRelativeProfitFormatting(from: profitStats)
            } else {
                profitValueLabel.text = Format.getAbsoluteProfitFormatting(from: profitStats, currency: portfolioManager.quoteCurrency)
            }
        }
    }
    
    // MARK: - Initialization
    init(viewFactory: ViewControllerFactory, kryptonService: KryptonDaemon, portfolioManager: PortfolioManager, tickerDaemon: TickerDaemon) {
        self.viewFactory = viewFactory
        self.kryptonDaemon = kryptonService
        self.portfolioManager = portfolioManager
        self.tickerDaemon = tickerDaemon
        
        super.init(nibName: nil, bundle: nil)
        
        title = "Dashboard"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(filterButtonPressed))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Customization
    override func viewDidLoad() {
        super.viewDidLoad()
        investmentLabel.text = "Total Investment"
        
        portfolioValueLabel.tag = 0
        portfolioValueLabel.isUserInteractionEnabled = true
        let portfolioValueTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(togglePortfolioDisplayType))
        portfolioValueLabel.addGestureRecognizer(portfolioValueTapRecognizer)
        
        profitValueLabel.tag = 1
        profitValueLabel.isUserInteractionEnabled = true
        let profitValueTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleProfitType))
        profitValueLabel.addGestureRecognizer(profitValueTapRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        kryptonDaemon.delegate = self
        tickerDaemon.delegate = self
        updateUI()
    }

    // MARK: - Private Methods
    @objc private func filterButtonPressed() {
        let filterViewController = viewFactory.makeFilterViewController()
        filterViewController.delegate = self
        filterViewController.isSelector = true
        filterViewController.filter.transactionType = filter.transactionType
        let filterNavigationController = UINavigationController(rootViewController: filterViewController)
        navigationController?.pushViewController(filterNavigationController, animated: true)
    }
    
    private func updateUI() {
        portfolioDisplay = { portfolioDisplay }()
        showsRelativeProfit = { showsRelativeProfit }()
        
        if let investmentValue = portfolioManager.getProfitStats(for: filter.transactionType, timeframe: .allTime)?.startValue {
            investmentValueLabel.text = Format.getCurrencyFormatting(for: investmentValue, currency: portfolioManager.quoteCurrency)
        } else {
            investmentValueLabel.text = "???"
        }
    }
    
    @objc private func toggleProfitType(sender: UITapGestureRecognizer) {
        showsRelativeProfit = !showsRelativeProfit
    }
    
    @objc private func togglePortfolioDisplayType(sender: UITapGestureRecognizer) {
        switch portfolioDisplay {
        case .currentExchangeValue:
            portfolioDisplay = .relativeProfit
        case .relativeProfit:
            portfolioDisplay = .absoluteProfit
        case .absoluteProfit:
            portfolioDisplay = .currentExchangeValue
        }
    }
    
    // MARK: - KryptonDaemon Delegate
    func kryptonDaemonDidUpdate(_ kryptonService: KryptonDaemon) {
        updateUI()
    }
    
    // MARK: - TickerDaemon Delegate
    func tickerDaemon(_ tickerDaemon: TickerDaemon, didUpdateCurrentExchangeRateForCurrencyPair currencyPair: CurrencyPair) {
        updateUI()
    }
    
    // MARK: - Filter Delegate
    func didChangeSelectedAddresses() {
        updateUI()
    }
    
    func didChangeTransactionType(type: TransactionType) {
        filter.transactionType = type
    }

}
