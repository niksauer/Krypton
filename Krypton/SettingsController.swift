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
    @IBOutlet weak var quoteCurrencyCodeLabel: UILabel!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        quoteCurrencyCodeLabel.text = PortfolioManager.shared.quoteCurrency.code
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
            destVC.selection = PortfolioManager.shared.quoteCurrency
            destVC.type = .Fiat
            destVC.title = "Base Currency"
        }
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - CurrencySelection Delegate
    func didSelectCurrency(selection: Currency) {
        do {
            try PortfolioManager.shared.setQuoteCurrency(selection)
        } catch {
            // present error
        }
    }
    
    // MARK: - PortfolioManager Delegate
    func didUpdatePortfolioManager() {
        quoteCurrencyCodeLabel.text = PortfolioManager.shared.quoteCurrency.code
    }
    
}
