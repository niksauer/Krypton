//
//  AddPortfolioViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 17.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit
import ToolKit

protocol PortfolioCreatorDelegate {
    func portfolioCreator(_ portfolioCreator: AddPortfolioViewController, didCreatePortfolio portfolio: Portfolio)
}

class AddPortfolioViewController: UITableViewController {

    // MARK: - Views
    private var saveBarButtonItem: UIBarButtonItem!
    
    // MARK: - Private Properties
    private let portfolioManager: PortfolioManager
    
    private var alias: String? {
        didSet {
            validateSaveButton()
        }
    }
    
    private var isDefault: Bool = false {
        didSet {
            validateSaveButton()
        }
    }
    
    // MARK: - Public Properties
    var delegate: PortfolioCreatorDelegate?
    
    // MARK: - Initialization
    init(portfolioManager: PortfolioManager) {
        self.portfolioManager = portfolioManager
        isDefault = (portfolioManager.defaultPortfolio == nil)
        
        super.init(style: .grouped)
        
        title = "Add Portfolio"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
        saveBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveButtonPressed))
        navigationItem.rightBarButtonItem = saveBarButtonItem
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Customization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // prototype cells
        tableView.register(TextFieldCell.self, forCellReuseIdentifier: "TextFieldCell")
        tableView.register(SwitchCell.self, forCellReuseIdentifier: "SwitchCell")
        
        // keyboard dismissal
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        tapGestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureRecognizer)
        
        validateSaveButton()
    }
    
    // MARK: - Public Methods
    @objc private func cancelButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func saveButtonPressed() {
        guard let alias = alias else {
            return
        }
        
        do {
            let portfolio = try portfolioManager.addPortfolio(alias: alias, quoteCurrency: portfolioManager.quoteCurrency)
            try portfolio.setIsDefault(isDefault)
            delegate?.portfolioCreator(self, didCreatePortfolio: portfolio)
            dismiss(animated: true, completion: nil)
        } catch {
            displayAlert(title: "Error", message: "Failed to create portfolio: \(error)", completion: nil)
        }
    }
    
    private func validateSaveButton() {
        guard let alias = alias?.trimmingCharacters(in: .whitespacesAndNewlines), !alias.isEmpty else {
            saveBarButtonItem.isEnabled = false
            return
        }
        
        saveBarButtonItem.isEnabled = true
    }
    
    @objc private func didChangeAlias(_ sender: UITextField) {
        self.alias = sender.text
    }
    
    @objc private func didChangeIsDefault(_ sender: UISwitch) {
        self.isDefault = sender.isOn
    }
    
    @objc private func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    // MARK: - TableView DataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        default:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        
        switch section {
        case 0:
            switch row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldCell
                cell.textField.placeholder = "Alias"
                cell.isEnabled = true
                cell.textField.addTarget(self, action: #selector(didChangeAlias(_:)), for: .editingChanged)
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
                cell.label.text = "Use as default"
                cell.switchControl.isOn = isDefault
                cell.switchControl.addTarget(self, action: #selector(didChangeIsDefault(_:)), for: .valueChanged)
                return cell
            default:
                fatalError()
            }
        default:
            fatalError()
        }
    }
    
}
