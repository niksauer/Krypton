//
//  SettingsController.swift
//  Krypton
//
//  Created by Niklas Sauer on 17.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class SettingsController: UITableViewController, FiatSelectionDelegate, PortfolioManagerDelegate {

    // MARK: - Outlets
    @IBOutlet weak var selectedFiatCurrencyLabel: UILabel!
    
    // MARK: - Initialization
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PortfolioManager.shared.delegate = self
        selectedFiatCurrencyLabel.text = PortfolioManager.shared.baseCurrency.rawValue
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destVC = segue.destination as? FiatSelectionController {
            destVC.delegate = self
            destVC.selection = PortfolioManager.shared.baseCurrency
        }
    }
    
    // MARK: - FiatCurrency Delegate
    func didSelectFiatCurrency(selection: Currency.Fiat) {
        do {
            try PortfolioManager.shared.setBaseCurrency(selection)
        } catch {
            print(error)
        }
    }
    
    // MARK: - PortfolioManager Delegate
    func didUpdatePortfolioManager() {
        selectedFiatCurrencyLabel.text = PortfolioManager.shared.baseCurrency.rawValue
    }
    
}
