//
//  DashboardViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit
import Charts

enum AnalysisType: String {
    case exchangeValue = "Exchange Value"
    case relativeProfit = "Relative Profit"
    case absoluteProfit = "Absolute Profit"
}

class DashboardViewController: UIViewController, KryptonDaemonDelegate, TickerDaemonDelegate, FilterDelegate, ChartViewDelegate {

    // Mark: - Outlets
    @IBOutlet weak var comparisonDateSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var analysisTypeLabel: UILabel!
    @IBOutlet weak var previousAnalysisTypeButton: UIButton!
    @IBOutlet weak var nextAnalysisTypeButton: UIButton!
    
    @IBOutlet weak var analysisChartViewContainer: UIView!
    @IBOutlet weak var insightsViewContainer: UIView!
    
    // MARK: - Private Properties
    private let viewFactory: ViewControllerFactory
    private let kryptonDaemon: KryptonDaemon
    private let portfolioManager: PortfolioManager
    private let tickerDaemon: TickerDaemon
    private let currencyFormatter: CurrencyFormatter
    private let taxAdviser: TaxAdviser
    private let comparisonDateFormatter: DateFormatter
    
    private let analysisChartViewController: AnalysisChartViewController
    private let insightsViewController: InsightsViewController
    
    private var timeframe: ChartTimeframe = .week {
        didSet {
            if let comparisonDate = timeframe.comparisonDate {
                self.comparisonDate = comparisonDate
            } else if let oldestTransaction = portfolioManager.getOldestTransaction() {
                self.comparisonDate = oldestTransaction.date!
            } else {
                self.comparisonDate = nil
            }
            
            analysisChartViewController.setXAxisLabelCount(timeframe.labelCount)
            analysisChartViewController.dateFormatter = timeframe.dateFormatter
            analysisChartViewController.comparisonDate = comparisonDate
            
            insightsViewController.comparisonDate = comparisonDate
        
            updateUI()
        }
    }
    
    private var comparisonDate: Date?
    
    private var filter: Filter = Filter() {
        didSet {
            analysisChartViewController.transactionType = filter.transactionType
            insightsViewController.transactionType = filter.transactionType
            
            updateUI()
        }
    }
    
    private var analysisType: AnalysisType = .exchangeValue {
        didSet {
            analysisChartViewController.type = analysisType
            insightsViewController.analysisType = analysisType
            
            updateUI()
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
        self.analysisChartViewController = AnalysisChartViewController(portfolioManager: portfolioManager, taxAdviser: taxAdviser, anaylsisType: analysisType, transactionType: filter.transactionType)
        self.insightsViewController = InsightsViewController(portfolioManager: portfolioManager, taxAdviser: taxAdviser, analysisType: analysisType, transactionType: filter.transactionType)
        
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
        
        // setup analysis charts VC
        addChildViewController(analysisChartViewController)
        analysisChartViewContainer.addSubview(analysisChartViewController.view)
        analysisChartViewController.didMove(toParentViewController: self)
        analysisChartViewController.view.translatesAutoresizingMaskIntoConstraints = false
        analysisChartViewController.view.pin(to: analysisChartViewContainer)
        
        // setup insights VC
        addChildViewController(insightsViewController)
        insightsViewContainer.addSubview(insightsViewController.view)
        insightsViewController.didMove(toParentViewController: self)
        insightsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        insightsViewController.view.pin(to: insightsViewContainer)
        
        // chart timeframe
        timeframe = .week
        
        // setup segmented control
        comparisonDateSegmentedControl.selectedSegmentIndex = timeframe.rawValue
        
        // final view refresh
        updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        kryptonDaemon.delegate = self
        tickerDaemon.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        kryptonDaemon.delegate = nil
        tickerDaemon.delegate = nil
    }

    // MARK: - Private Methods
    private func updateUI() {
        analysisTypeLabel.text = analysisType.rawValue

//
        
//        if let investmentValue = taxAdviser.getProfitStats(for: portfolioManager.selectedAddresses, timeframe: .allTime, type: filter.transactionType)?.startValue {
//            investmentValueLabel.text = currencyFormatter.getFormatting(for: investmentValue, currency: portfolioManager.quoteCurrency)
//        } else {
//            investmentValueLabel.text = "???"
//        }
//
//        //            guard let currentExchangeValue = taxAdviser.getExchangeValue(for: portfolioManager.selectedAddresses, on: Date(), type: filter.transactionType), let profitStats = taxAdviser.getProfitStats(for: portfolioManager.selectedAddresses, timeframe: .allTime, type: filter.transactionType) else {
//        //                portfolioValueLabel.text = "???"
//        //                return
//        //            }
//
//        //            switch analysisType {
//        //            case .exchangeValue:
//        //                portfolioValueLabel.text = currencyFormatter.getFormatting(for: currentExchangeValue, currency: portfolioManager.quoteCurrency)
//        //            case .relativeProfit:
//        //                portfolioValueLabel.text = currencyFormatter.getRelativeProfitFormatting(from: profitStats)
//        //            case .absoluteProfit:
//        //                portfolioValueLabel.text = currencyFormatter.getAbsoluteProfitFormatting(from: profitStats, currency: portfolioManager.quoteCurrency)
//        //            }
//
//        switch analysisType {
//        case .absoluteProfit:
//            showsRelativeProfit = false
//        case .relativeProfit:
//            showsRelativeProfit = true
//        default:
//            break
//        }
//
//        portfolioLabel.text = analysisType.rawValue
//
//        guard let comparisonDate = comparisonDate else {
//            return
//        }
//
//        guard let profitStats = taxAdviser.getProfitStats(for: portfolioManager.selectedAddresses, timeframe: .sinceDate(comparisonDate), type: filter.transactionType) else {
//            profitValueLabel.text = "???"
//            return
//        }
//
//        profitLabel.text = "Since \(comparisonDateFormatter.string(from: comparisonDate))"
//
//        if showsRelativeProfit {
//            profitValueLabel.text = currencyFormatter.getRelativeProfitFormatting(from: profitStats)
//        } else {
//            profitValueLabel.text = currencyFormatter.getAbsoluteProfitFormatting(from: profitStats, currency: portfolioManager.quoteCurrency)
//        }
    }
    
    @objc private func filterButtonPressed() {
        let filterViewController = viewFactory.makeFilterViewController(showsAdvancedProperties: false, isAddressSelector: true)
        filterViewController.delegate = self
        filterViewController.filter = filter
        let filterNavigationController = UINavigationController(rootViewController: filterViewController)
        navigationController?.present(filterNavigationController, animated: true)
    }
    
    @IBAction func previousAnalysisTypeButtonPressed(_ sender: UIButton) {
        switch analysisType {
        case .exchangeValue:
            analysisType = .absoluteProfit
        case .relativeProfit:
            analysisType = .exchangeValue
        case .absoluteProfit:
            analysisType = .relativeProfit
        }
    }
    
    @IBAction func nextAnalysisTypeButtonPressed(_ sender: UIButton) {
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
