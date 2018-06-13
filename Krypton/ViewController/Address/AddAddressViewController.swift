//
//  AddAddressViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 15.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit
import ToolKit

class AddAddressViewController: UITableViewController, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate, PortfolioSelectorDelegate {
    
    // MARK: - Views
    private var saveBarButtonItem: UIBarButtonItem!
    
    // MARK: - Private Properties
    private let viewFactory: ViewControllerFactory
    private let portfolioManager: PortfolioManager
    private let blockchains: [Blockchain]
    
    private let selectedBlockchainIndexPath = IndexPath(row: 0, section: 1)
    private let blockchainPickerViewIndexPath = IndexPath(row: 1, section: 1)
    private let selectedPortfolioIndexPath = IndexPath(row: 0, section: 2)
    
    private var isBlockchainPickerViewHidden = true
    
    private var address: String? {
        didSet {
            validateSaveButton()
        }
    }
    
    private var alias: String? {
        didSet {
            validateSaveButton()
        }
    }
    
    private var selectedBlockchain: Blockchain? {
        didSet {
            validateSaveButton()
            tableView.reloadRows(at: [selectedBlockchainIndexPath], with: .automatic)
        }
    }
    
    private var selectedPortfolio: Portfolio? {
        didSet {
            validateSaveButton()
            tableView.reloadRows(at: [selectedPortfolioIndexPath], with: .automatic)
        }
    }
    
    // MARK: - Initialization
    init(viewFactory: ViewControllerFactory, portfolioManager: PortfolioManager, blockchains: [Blockchain]) {
        self.viewFactory = viewFactory
        self.portfolioManager = portfolioManager
        self.blockchains = blockchains
        
        selectedBlockchain = blockchains.first
        selectedPortfolio = portfolioManager.defaultPortfolio
        
        super.init(style: .grouped)

        title = "Add Address"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
        saveBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveButtonPressed))
        navigationItem.rightBarButtonItem = saveBarButtonItem
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(TextFieldCell.self, forCellReuseIdentifier: "TextFieldCell")
        tableView.register(PickerViewCell.self, forCellReuseIdentifier: "PickerViewCell")
        
        validateSaveButton()
    }
    
    // MARK: - Private Methods
    @objc private func cancelButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func saveButtonPressed() {
        guard let address = address, let selectedBlockchain = selectedBlockchain, let selectedPortfolio = selectedPortfolio else {
            return
        }
        
        do {
            try selectedPortfolio.addAddress(address, alias: alias, blockchain: selectedBlockchain)
            dismiss(animated: true, completion: nil)
        } catch {
            // TODO: present error
        }
    }
    
    private func validateSaveButton() {
        guard let address = address?.trimmingCharacters(in: .whitespacesAndNewlines), !address.isEmpty, selectedPortfolio != nil, selectedBlockchain != nil else {
            saveBarButtonItem.isEnabled = false
            // TODO: handle input error
            return
        }
        
        saveBarButtonItem.isEnabled = true
    }
    
    @objc private func didChangeAddress(_ sender: UITextField) {
        self.address = sender.text
    }
    
    @objc private func didChangeAlias(_ sender: UITextField) {
        self.alias = sender.text
    }
    
    // MARK: - PortfolioSelector Delegate
    func portfolioSelector(_ portfolioSelector: PortfoliosViewController, didChangeSelectedPortfolio portfolio: Portfolio?) {
        selectedPortfolio = portfolio
    }
    
    // MARK: - TableView DataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return  2
        case 2:
            return 1
        default:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        
        switch section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as! TextFieldCell
            
            switch row {
            case 0:
                cell.textField.placeholder = "Address"
                cell.isEnabled = true
                cell.textField.addTarget(self, action: #selector(didChangeAddress(_:)), for: .editingChanged)
            case 1:
                cell.textField.placeholder = "Alias"
                cell.isEnabled = true
                cell.textField.addTarget(self, action: #selector(didChangeAlias(_:)), for: .editingChanged)
            default:
                fatalError()
            }
            
            return cell
        case 1:
            switch row {
            case 0:
                let cell = UITableViewCell(style: .value1, reuseIdentifier: "InfoCell")
                cell.textLabel?.text = "Blockchain"
                cell.detailTextLabel?.text = selectedBlockchain?.name
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "PickerViewCell", for: indexPath) as! PickerViewCell
                cell.pickerView.dataSource = self
                cell.pickerView.delegate = self
                return cell
            default:
                fatalError()
            }
        case 2:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "InfoCell")
            cell.textLabel?.text = "Portfolio"
            cell.detailTextLabel?.text = selectedPortfolio?.alias ?? "None"
            cell.accessoryType = .disclosureIndicator
            return cell
        default:
            fatalError()
        }
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath {
        case blockchainPickerViewIndexPath:
            if isBlockchainPickerViewHidden {
                return 0
            } else {
                return 220
            }
        default:
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case selectedBlockchainIndexPath:
            isBlockchainPickerViewHidden = !isBlockchainPickerViewHidden
            
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.tableView.beginUpdates()
                // apple bug fix - some TV lines hide after animation
                self.tableView.deselectRow(at: indexPath, animated: true)
                self.tableView.endUpdates()
            })
        case selectedPortfolioIndexPath:
            let portfolioSelectionViewController = viewFactory.makePortfolioSelectorViewController(selection: selectedPortfolio)
            portfolioSelectionViewController.delegate = self
            navigationController?.pushViewController(portfolioSelectionViewController, animated: true)
        default:
            return
        }
    }
    
    // MARK: - PickerView DataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return blockchains.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return blockchains[row].name
    }
    
    // MARK: - PickerView Delegate
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedBlockchain = blockchains[row]
    }
    
}
