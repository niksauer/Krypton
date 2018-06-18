//
//  InsightsViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 18.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class InsightsViewController: UICollectionViewController {

    // Mark: - Private Properties
    private let portfolioManager: PortfolioManager
    private let taxAdviser: TaxAdviser
    
    // Mark: - Public Properties
    var analysisType: AnalysisType {
        didSet {
            updateUI()
        }
    }
    
    var transactionType: TransactionType {
        didSet {
            updateUI()
        }
    }
    
    var comparisonDate: Date? {
        didSet {
            updateUI()
        }
    }
    
    // MARK: Initialization
    init(portfolioManager: PortfolioManager, taxAdviser: TaxAdviser, analysisType: AnalysisType, transactionType: TransactionType) {
        self.portfolioManager = portfolioManager
        self.taxAdviser = taxAdviser
        self.analysisType = analysisType
        self.transactionType = transactionType
        
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        
        collectionView!.alwaysBounceVertical = true
        collectionView?.backgroundColor = UIColor.groupTableViewBackground
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Customization
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }
    
    // MARK: Private Methods
    private func updateUI() {
        
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
        // Configure the cell
    
        return cell
    }
    
}
