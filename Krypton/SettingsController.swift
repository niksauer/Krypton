//
//  SettingsController.swift
//  Krypton
//
//  Created by Niklas Sauer on 17.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class SettingsController: UITableViewController, CurrencySelectionDelegate, PortfolioManagerDelegate {

    // MARK: - Outlets
    @IBOutlet weak var baseCurrencyCodeLabel: UILabel!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        baseCurrencyCodeLabel.text = PortfolioManager.shared.baseCurrency.code
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PortfolioManager.shared.delegate = self
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destVC = segue.destination as? CurrencySelectionController {
            destVC.delegate = self
            destVC.selection = PortfolioManager.shared.baseCurrency
        }
    }
    
    // MARK: - CurrencySelection Delegate
    func didSelectCurrency(selection: Currency) {
        do {
            try PortfolioManager.shared.setBaseCurrency(selection)
        } catch {
            // present error
            print(error)
        }
    }
    
    // MARK: - PortfolioManager Delegate
    func didUpdatePortfolioManager() {
        baseCurrencyCodeLabel.text = PortfolioManager.shared.baseCurrency.code
    }
    
}
