//
//  InsightsViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 18.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class InsightsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    // Mark: - Private Properties
    private let portfolioManager: PortfolioManager
    private let taxAdviser: TaxAdviser
    private let currencyFormatter: CurrencyFormatter
    private let comparisonDateFormatter: DateFormatter
    
    // Mark: - Public Properties
    var analysisType: AnalysisType
    var transactionType: TransactionType
    var comparisonDate: Date?
    
    // MARK: Initialization
    init(portfolioManager: PortfolioManager, taxAdviser: TaxAdviser, currencyFormatter: CurrencyFormatter, comparisonDateFormatter: DateFormatter, analysisType: AnalysisType, transactionType: TransactionType) {
        self.portfolioManager = portfolioManager
        self.taxAdviser = taxAdviser
        self.currencyFormatter = currencyFormatter
        self.comparisonDateFormatter = comparisonDateFormatter
        self.analysisType = analysisType
        self.transactionType = transactionType
    
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        super.init(collectionViewLayout: layout)
        
        collectionView!.alwaysBounceVertical = true
        collectionView?.backgroundColor = UIColor.white
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
    
    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InsightCell", for: indexPath) as! InsightCell
        let row = indexPath.row
        
        switch row {
        case 0:
            cell.label.text = "Total Value"
            
            if let exchangeValue = taxAdviser.getExchangeValue(for: portfolioManager.selectedAddresses, on: Date(), type: transactionType) {
                cell.detailLabel.text = currencyFormatter.getFormatting(for: exchangeValue, currency: portfolioManager.quoteCurrency, maxDigits: 0)
            } else {
                cell.detailLabel.text = "???"
            }
            
            cell.subtitleLabel.text = nil
        case 1:
            switch analysisType {
            case .absoluteProfit:
                cell.label.text = "Absolute Profit"
            default:
                cell.label.text = "Relative Profit"
            }
            
            if let comparisonDate = comparisonDate, let profitStats = taxAdviser.getProfitStats(for: portfolioManager.selectedAddresses, timeframe: .sinceDate(comparisonDate), type: transactionType) {
                switch analysisType {
                case .absoluteProfit:
                    cell.detailLabel.text = currencyFormatter.getAbsoluteProfitFormatting(from: profitStats, currency: portfolioManager.quoteCurrency, maxDigits: 0)
                default:
                    cell.detailLabel.text = currencyFormatter.getRelativeProfitFormatting(from: profitStats, maxDigits: 2)
                }
                
                cell.subtitleLabel.text = "Since \(comparisonDateFormatter.string(from: comparisonDate))"
            } else {
                cell.detailLabel.text = "???"
                cell.subtitleLabel.text = nil
            }
        case 2:
            cell.label.text = "Total Investment"
            
            if let investmentValue = taxAdviser.getProfitStats(for: portfolioManager.selectedAddresses, timeframe: .allTime, type: transactionType)?.startValue {
                cell.detailLabel.text = currencyFormatter.getFormatting(for: investmentValue, currency: portfolioManager.quoteCurrency, maxDigits: 0)
            } else {
                cell.detailLabel.text = "???"
            }
            
            cell.subtitleLabel.text = nil
        default:
            fatalError()
        }
        
        return cell
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width - 32, height: 80)
    }
    
}
