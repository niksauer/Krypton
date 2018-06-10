//
//  AddPortfolioViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 17.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

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
        
        tableView.register(UINib(nibName: "TextFieldCell", bundle: nil), forCellReuseIdentifier: "TextFieldCell")
        tableView.register(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: "SwitchCell")
        
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
            // TODO: present error
        }
    }
    
    private func validateSaveButton() {
        guard let alias = alias?.trimmingCharacters(in: .whitespacesAndNewlines), !alias.isEmpty else {
            saveBarButtonItem.isEnabled = false
            return
        }
        
        saveBarButtonItem.isEnabled = true
    }
    
    private func didChangeAlias(_ alias: String?) {
        self.alias = alias
    }
    
    private func didChangeIsDefault(_ isDefault: Bool) {
        self.isDefault = isDefault
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
                cell.configure(text: nil, placeholder: "Alias", isEnabled: true, onChange: didChangeAlias(_:))
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchCell
                cell.configure(name: "Use as default", isOn: isDefault, onChange: didChangeIsDefault(_:))
                return cell
            default:
                fatalError()
            }
        default:
            fatalError()
        }
    }
    
}
