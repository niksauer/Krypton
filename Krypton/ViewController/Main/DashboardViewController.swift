//
//  DashboardViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit
import Charts

class DashboardViewController: UIViewController, KryptonDaemonDelegate, TickerDaemonDelegate, FilterDelegate, ChartViewDelegate {

    // Mark: - Outlets
    @IBOutlet weak var comparisonDateSegmentedControl: UISegmentedControl!
    @IBOutlet weak var chartsViewContainer: UIView!
    
    @IBOutlet weak var portfolioValueLabel: UILabel!
    @IBOutlet weak var portfolioLabel: UILabel!
    @IBOutlet weak var profitValueLabel: UILabel!
    @IBOutlet weak var profitLabel: UILabel!
    @IBOutlet weak var investmentValueLabel: UILabel!
    @IBOutlet weak var investmentLabel: UILabel!
    
    // MARK: - Private Types
    private enum AnalysisType {
        case exchangeValue
        case relativeProfit
        case absoluteProfit
    }
    
    // MARK: - Private Properties
    private let viewFactory: ViewControllerFactory
    private let kryptonDaemon: KryptonDaemon
    private let portfolioManager: PortfolioManager
    private let tickerDaemon: TickerDaemon
    private let currencyFormatter: CurrencyFormatter
    private let taxAdviser: TaxAdviser
    private let comparisonDateFormatter: DateFormatter
    
    private let chartsPageViewController: ChartsPageViewController
    
    private var timeframe: ChartTimeframe = .week {
        didSet {
            if let comparisonDate = timeframe.comparisonDate {
                self.comparisonDate = comparisonDate
            } else if let oldestTransaction = portfolioManager.getOldestTransaction() {
                self.comparisonDate = oldestTransaction.date!
            }
            
            chartsPageViewController.setXAxisLabelCount(timeframe.labelCount)
            chartsPageViewController.setDateFormatter(timeframe.dateFormatter)
            chartsPageViewController.setComparisonDate(comparisonDate)
            
//            analysisChartsViewController.setXAxisLabelCount(timeframe.labelCount)
//            analysisChartsViewController.dateFormatter = timeframe.dateFormatter
//            analysisChartsViewController.comparisonDate = comparisonDate
            
            updateUI()
        }
    }
    
    private var comparisonDate: Date?
    
    private var filter: Filter = Filter() {
        didSet {
            updateUI()
        }
    }
    
    private var analysisType: AnalysisType = .exchangeValue {
        didSet {
            guard let currentExchangeValue = taxAdviser.getExchangeValue(for: portfolioManager.selectedAddresses, on: Date(), type: filter.transactionType), let profitStats = taxAdviser.getProfitStats(for: portfolioManager.selectedAddresses, timeframe: .allTime, type: filter.transactionType) else {
                portfolioValueLabel.text = "???"
                return
            }
            
            switch analysisType {
            case .exchangeValue:
                portfolioLabel.text = "Total Value"
                portfolioValueLabel.text = currencyFormatter.getFormatting(for: currentExchangeValue, currency: portfolioManager.quoteCurrency)
            case .relativeProfit:
                portfolioLabel.text = "Total Relative Profit"
                portfolioValueLabel.text = currencyFormatter.getRelativeProfitFormatting(from: profitStats)
            case .absoluteProfit:
                portfolioLabel.text = "Total Absolute Profit"
                portfolioValueLabel.text = currencyFormatter.getAbsoluteProfitFormatting(from: profitStats, currency: portfolioManager.quoteCurrency)
            }
        }
    }
    
    private var showsRelativeProfit: Bool = true {
        didSet {
            guard let comparisonDate = comparisonDate else {
                return
            }
            
            guard let profitStats = taxAdviser.getProfitStats(for: portfolioManager.selectedAddresses, timeframe: .sinceDate(comparisonDate), type: filter.transactionType) else {
                profitValueLabel.text = "???"
                return
            }

            profitLabel.text = "Since \(comparisonDateFormatter.string(from: comparisonDate))"
            
            if showsRelativeProfit {
                profitValueLabel.text = currencyFormatter.getRelativeProfitFormatting(from: profitStats)
            } else {
                profitValueLabel.text = currencyFormatter.getAbsoluteProfitFormatting(from: profitStats, currency: portfolioManager.quoteCurrency)
            }
        }
    }
    
    // MARK: - Initialization
    init(viewFactory: ViewControllerFactory, kryptonDaemon: KryptonDaemon, portfolioManager: PortfolioManager, tickerDaemon: TickerDaemon, currencyFormatter: CurrencyFormatter, taxAdviser: TaxAdviser, comparisonDateFormatter: DateFormatter) {
        self.viewFactory = viewFactory
        self.kryptonDaemon = kryptonDaemon
        self.portfolioManager = portfolioManager
        self.tickerDaemon = tickerDaemon
        self.currencyFormatter = currencyFormatter
        self.taxAdviser = taxAdviser
        self.comparisonDateFormatter = comparisonDateFormatter
        self.chartsPageViewController = ChartsPageViewController(portfolioManager: portfolioManager, taxAdviser: taxAdviser, transactionType: filter.transactionType)
        
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
        
        // portfolio
        portfolioValueLabel.isUserInteractionEnabled = true
        let portfolioValueTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleAnalysisType))
        portfolioValueLabel.addGestureRecognizer(portfolioValueTapRecognizer)
        
        // profit
        profitValueLabel.isUserInteractionEnabled = true
        let profitValueTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleProfitType))
        profitValueLabel.addGestureRecognizer(profitValueTapRecognizer)
        
        // investment
        investmentLabel.text = "Total Investment"
        
        // setup analysis charts VC
        addChildViewController(chartsPageViewController)
        chartsViewContainer.addSubview(chartsPageViewController.view)
        chartsPageViewController.didMove(toParentViewController: self)
        chartsPageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        chartsPageViewController.view.pin(to: chartsViewContainer)
        
//        addChildViewController(analysisChartsViewController)
//        chartsViewContainer.addSubview(analysisChartsViewController.view)
//        analysisChartsViewController.didMove(toParentViewController: self)
//        analysisChartsViewController.view.translatesAutoresizingMaskIntoConstraints = false
//        analysisChartsViewController.view.pin(to: chartsViewContainer)
    
        // chart timeframe
        timeframe = .week
        
        // setup segmented control
        comparisonDateSegmentedControl.selectedSegmentIndex = timeframe.rawValue
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        kryptonDaemon.delegate = self
        tickerDaemon.delegate = self
        
        updateUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        kryptonDaemon.delegate = nil
        tickerDaemon.delegate = nil
    }

    // MARK: - Private Methods
    private func updateUI() {
        analysisType = { analysisType }()
        showsRelativeProfit = { showsRelativeProfit }()
        
        if let investmentValue = taxAdviser.getProfitStats(for: portfolioManager.selectedAddresses, timeframe: .allTime, type: filter.transactionType)?.startValue {
            investmentValueLabel.text = currencyFormatter.getFormatting(for: investmentValue, currency: portfolioManager.quoteCurrency)
        } else {
            investmentValueLabel.text = "???"
        }
    }
    
    @objc private func filterButtonPressed() {
        let filterViewController = viewFactory.makeFilterViewController(showsAdvancedProperties: false, isAddressSelector: true)
        filterViewController.delegate = self
        filterViewController.filter = filter
        let filterNavigationController = UINavigationController(rootViewController: filterViewController)
        navigationController?.present(filterNavigationController, animated: true)
    }
    
    @objc private func toggleProfitType(sender: UITapGestureRecognizer) {
        showsRelativeProfit = !showsRelativeProfit
    }
    
    @objc private func toggleAnalysisType(sender: UITapGestureRecognizer) {
        switch analysisType {
        case .exchangeValue:
            analysisType = .relativeProfit
        case .relativeProfit:
            analysisType = .absoluteProfit
        case .absoluteProfit:
            analysisType = .exchangeValue
        }
    }
    
    @IBAction private func didChangeChartTimeframe(_ sender: UISegmentedControl) {
        timeframe = ChartTimeframe(rawValue: sender.selectedSegmentIndex)!
    }
    
    // MARK: - ChartView Delegate
    
    // MARK: - KryptonDaemon Delegate
    func kryptonDaemonDidUpdate(_ kryptonDaemon: KryptonDaemon) {
        updateUI()
    }
    
    // MARK: - TickerDaemon Delegate
    func tickerDaemon(_ tickerDaemon: TickerDaemon, didUpdateCurrentExchangeRateForCurrencyPair currencyPair: CurrencyPair) {
        updateUI()
    }
    
    // MARK: - FilterController Delegate
    func filterControllerDidSetSelectedAddresses(_ filterController: FilterViewController) {
        updateUI()
    }
 
    func filterController(_ filterController: FilterViewController, didSetTransactionType type: TransactionType) {
        filter.transactionType = type
    }
    
}
