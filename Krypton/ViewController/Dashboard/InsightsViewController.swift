//
//  InsightsViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 18.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class InsightsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    // Mark: - Typealiases
    typealias ColorPalette = DashboardColorPalette
    
    // Mark: - Private Properties
    private let portfolioManager: PortfolioManager
    private let taxAdviser: TaxAdviser
    private let currencyFormatter: CurrencyFormatter
    private let comparisonDateFormatter: DateFormatter
    private let colorPalette: ColorPalette
    
    private var showsAbsoluteProfit: Bool
    
    // Mark: - Public Properties
    var analysisType: AnalysisType {
        didSet {
            showsAbsoluteProfit = analysisType == .absoluteProfit
        }
    }
    
    var transactionType: TransactionType
    var comparisonDate: Date?
    
    // MARK: Initialization
    init(portfolioManager: PortfolioManager, taxAdviser: TaxAdviser, currencyFormatter: CurrencyFormatter, comparisonDateFormatter: DateFormatter, colorPalette: ColorPalette, analysisType: AnalysisType, transactionType: TransactionType) {
        self.portfolioManager = portfolioManager
        self.taxAdviser = taxAdviser
        self.currencyFormatter = currencyFormatter
        self.comparisonDateFormatter = comparisonDateFormatter
        self.colorPalette = colorPalette
        self.analysisType = analysisType
        self.transactionType = transactionType
        
        showsAbsoluteProfit = analysisType == .absoluteProfit
    
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        super.init(collectionViewLayout: layout)
        
        collectionView!.alwaysBounceVertical = true
        collectionView!.backgroundColor = colorPalette.backgroundColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Customization
    override func viewDidLoad() {
        super.viewDidLoad()

        // register cells
        self.collectionView!.register(UINib.init(nibName: "InsightCell", bundle: nil), forCellWithReuseIdentifier: "InsightCell")
    }
    
    // MARK: Public Methods
    func updateUI() {
        collectionView?.reloadData()
    }
    
    // MARK: UICollectionView DataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InsightCell", for: indexPath) as! InsightCell
        cell.backgroundColor = colorPalette.insightBackgroundColor
        cell.label.textColor = colorPalette.primaryTextColor
        cell.subtitleLabel.textColor = colorPalette.secondaryTextColor
        cell.detailLabel.textColor = colorPalette.neutralColor
        
        let row = indexPath.row
        
        switch row {
        case 0:
            cell.label.text = "Total Value"
            cell.subtitleLabel.text = nil
            
            guard let profitStats = taxAdviser.getProfitStats(for: portfolioManager.selectedAddresses, timeframe: .allTime, type: transactionType) else {
                cell.detailLabel.text = "???"
                break
            }
            
            cell.detailLabel.text = currencyFormatter.getFormatting(for: profitStats.endValue, currency: portfolioManager.quoteCurrency, maxDigits: 0)
            
            if profitStats.endValue >= profitStats.startValue {
                cell.detailLabel.textColor = colorPalette.positiveColor
            } else {
                cell.detailLabel.textColor = colorPalette.negativeColor
            }
        case 1:
            if showsAbsoluteProfit {
                cell.label.text = "Absolute Profit"
            } else {
                cell.label.text = "Relative Profit"
            }
            
            guard let comparisonDate = comparisonDate, let profitStats = taxAdviser.getProfitStats(for: portfolioManager.selectedAddresses, timeframe: .sinceDate(comparisonDate), type: transactionType) else {
                cell.detailLabel.text = "???"
                cell.subtitleLabel.text = nil
                break
            }
            
            let profit: Double
            
            if showsAbsoluteProfit {
                profit = taxAdviser.getAbsoluteProfit(from: profitStats)
                cell.detailLabel.text = currencyFormatter.getFormatting(for: profit, currency: portfolioManager.quoteCurrency, maxDigits: 0)
            } else {
                profit = taxAdviser.getRelativeProfit(from: profitStats)
                cell.detailLabel.text = currencyFormatter.getPercentageFormatting(for: profit, maxDigits: 2)
            }
            
            if profit >= 0 {
                cell.detailLabel.textColor = colorPalette.positiveColor
            } else {
                cell.detailLabel.textColor = colorPalette.negativeColor
            }
            
            cell.subtitleLabel.text = "Since \(comparisonDateFormatter.string(from: comparisonDate))"
        case 2:
            cell.label.text = "Total Investment"
            cell.subtitleLabel.text = nil
            
            guard let investmentValue = taxAdviser.getProfitStats(for: portfolioManager.selectedAddresses, timeframe: .allTime, type: transactionType)?.startValue else {
                cell.detailLabel.text = "???"
                break
            }
            
            cell.detailLabel.text = currencyFormatter.getFormatting(for: investmentValue, currency: portfolioManager.quoteCurrency, maxDigits: 0)
        default:
            fatalError()
        }
        
        return cell
    }
    
    // MARK: UICollectionView Delegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = indexPath.row
        
        switch row {
        case 1:
            showsAbsoluteProfit = !showsAbsoluteProfit
            collectionView.reloadItems(at: [indexPath])
        default:
            break
        }
    }
    
    // MARK: UICollectionViewFlowLayout Delegate
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width - 32, height: 80)
    }
    
}
