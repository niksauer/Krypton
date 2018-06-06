//
//  TransactionTableController.swift
//  Krypton
//
//  Created by Niklas Sauer on 22.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit
import CoreData

class TransactionsViewController: FetchedResultsTableViewController<Transaction>, UITextFieldDelegate, FilterDelegate {
    
    // MARK: - Private Properties
    private let viewFactory: ViewControllerFactory
    private let portfolioManager: PortfolioManager
    private let searchContext: NSManagedObjectContext
    private let dateFormatter: DateFormatter
    private let updateDateFormatter: DateFormatter
    private let currencyFormatter: CurrencyFormatter
    
    private var addresses: [Address] {
        didSet {
            updateUI()
        }
    }
    
    private var selectedTransaction: Transaction?
    private var saveExchangeValueAction: UIAlertAction!
    
    private var updateTimer: Timer?
    
    private var isUpdating = false {
        didSet {
            updateToolbar()
        }
    }
    
    private var selectedTransactions: [Transaction]? {
        guard let selectedIndexPaths = self.tableView.indexPathsForSelectedRows else {
            return nil
        }
        
        var selectedTransactions = [Transaction]()
        
        for indexPath in selectedIndexPaths {
            let transaction = self.fetchedResultsController!.object(at: indexPath)
            selectedTransactions.append(transaction)
        }
        
        return selectedTransactions
    }
    
    // MARK: - Public Properties
    
    
    var isFilterActive = false {
        didSet {
            updateUI()
        }
    }
    
    var filter = Filter() {
        didSet {
            updateUI()
        }
    }
    
    var showsExchangeValue = false {
        didSet {
            updateUI()
        }
    }
    
    // MARK: - Initialization
    init(viewFactory: ViewControllerFactory, addresses: [Address], portfolioManager: PortfolioManager, searchContext: NSManagedObjectContext, dateFormatter: DateFormatter, updateDateFormatter: DateFormatter, currencyFormatter: CurrencyFormatter) {
        self.viewFactory = viewFactory
        self.addresses = addresses
        self.portfolioManager = portfolioManager
        self.searchContext = searchContext
        self.dateFormatter = dateFormatter
        self.updateDateFormatter = updateDateFormatter
        self.currencyFormatter = currencyFormatter
        
        super.init(style: .plain)
        
        tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Customization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(updateAddresses), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateUI()
        startUpdateTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopUpdateTimer()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        updateToolbar()
    }

    // MARK: - Private Methods
    @objc private func showFilterPanel() {
        let filterViewController = viewFactory.makeFilterViewController()
        let filterNavigationController = UINavigationController(rootViewController: filterViewController)
        
        filterViewController.delegate = self
        filterViewController.isSelector = false
        filterViewController.showsAdvancedProperties = true
        filterViewController.filter.transactionType = filter.transactionType
        filterViewController.filter.isUnread = filter.isUnread
        filterViewController.filter.isError = filter.isError
        filterViewController.filter.hasUserExchangeValue = filter.hasUserExchangeValue
        
        navigationController?.present(filterNavigationController, animated: true, completion: nil)
    }
    
    // MARK: UI Initialization
    private func updateUI() {
        updateData()
        updateToolbar()
        
        if let transactions = fetchedResultsController?.fetchedObjects, transactions.count > 0 {
            self.navigationItem.rightBarButtonItem = self.editButtonItem
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    private func updateData() {
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        // mandadory predicates
        let ownerPredicate = NSPredicate(format: "owner IN %@", addresses)
        
        // optional predicates
        var transactionTypePredicate: NSPredicate?
        var isUnreadPredicate: NSPredicate?
        var isErrorPredicate: NSPredicate?
        var hasUserExchangeValuePredicate: NSPredicate?
        
        if isFilterActive {
            switch filter.transactionType {
            case .investment:
                transactionTypePredicate = NSPredicate(format: "isInvestment = YES", addresses)
            case .other:
                transactionTypePredicate = NSPredicate(format: "isInvestment = NO", addresses)
            default:
                break
            }
            
            if filter.isError {
                isErrorPredicate = NSPredicate(format: "isError = YES")
            }
            
            if filter.isUnread {
                isUnreadPredicate = NSPredicate(format: "isUnread = YES")
            }
            
            if filter.hasUserExchangeValue {
                hasUserExchangeValuePredicate = NSPredicate(format: "userExchangeValue != -1")
            }
        }
        
        // final predicates
        let applicablePredicates = [ownerPredicate, transactionTypePredicate, isUnreadPredicate, isErrorPredicate, hasUserExchangeValuePredicate].compactMap { $0 }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: applicablePredicates)
        
        fetchedResultsController = NSFetchedResultsController<Transaction>(
            fetchRequest: request,
            managedObjectContext: searchContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        fetchedResultsController?.delegate = self
        try? fetchedResultsController?.performFetch()
        tableView.reloadData()
    }
    
    private func updateToolbar() {
        let flexibleSpacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        if isEditing {
            let isEnabled: Bool
            
            if let selectedTransactions = tableView.indexPathsForSelectedRows, selectedTransactions.count > 0 {
                isEnabled = true
            } else {
                isEnabled = false
            }
            
            let investmentButton = UIBarButtonItem(image: #imageLiteral(resourceName: "OT_label"), style: .plain, target: self, action: #selector(setIsInvestment))
            investmentButton.isEnabled = isEnabled
            
            let exchangeValueButton = UIBarButtonItem(image: #imageLiteral(resourceName: "OT_money-bag"), style: .plain, target: self, action: #selector(showExchangeValueActionSheet))
            exchangeValueButton.isEnabled = isEnabled
            
            let readButton = UIBarButtonItem(image: #imageLiteral(resourceName: "OT_double-tick"), style: .plain, target: self, action: #selector(setIsUnread))
            readButton.isEnabled = isEnabled
            
            self.toolbarItems = [investmentButton, flexibleSpacer, exchangeValueButton, flexibleSpacer, readButton]
        } else {
            let filterButton: UIBarButtonItem
            
            if isFilterActive {
                filterButton = UIBarButtonItem(image: #imageLiteral(resourceName: "OT_mail-filter-filled"), style: .plain, target: self, action: #selector(toggleIsFilterActive))
            } else {
                filterButton = UIBarButtonItem(image: #imageLiteral(resourceName: "OT_mail-filter"), style: .plain, target: self, action: #selector(toggleIsFilterActive))
            }
            
            let messageItem = getToolbarMessage()
            
            let valueButton: UIBarButtonItem
            
            if showsExchangeValue {
                valueButton = UIBarButtonItem(image: #imageLiteral(resourceName: "OT_us-dollar-filled"), style: .plain, target: self, action: #selector(toggleShowsExchangeValue))
            } else {
                valueButton = UIBarButtonItem(image: #imageLiteral(resourceName: "OT_us-dollar"), style: .plain, target: self, action: #selector(toggleShowsExchangeValue))
            }
            
            self.toolbarItems = [filterButton, flexibleSpacer, messageItem, flexibleSpacer, valueButton].compactMap { $0 }
        }
        
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    private func getToolbarMessage() -> UIBarButtonItem? {
        if isFilterActive {
            let filterButton = UIButton()
            filterButton.titleLabel?.numberOfLines = 0
            filterButton.titleLabel?.font = filterButton.titleLabel?.font.withSize(12)
            filterButton.titleLabel?.textAlignment = .center
            filterButton.titleLabel?.backgroundColor = UIColor.clear
            
            let title = NSMutableAttributedString(string: "Filtered by:\n")
            title.append(NSMutableAttributedString(string: filter.description, attributes: [
                NSAttributedStringKey.foregroundColor : self.view.tintColor
                ]))
            
            filterButton.setAttributedTitle(title, for: .normal)
            filterButton.sizeToFit()
            
            filterButton.addTarget(self, action: #selector(showFilterPanel), for: .touchUpInside)
            
            return UIBarButtonItem(customView: filterButton)
        } else {
            let messageLabel = UILabel()
            messageLabel.numberOfLines = 0
            messageLabel.font = messageLabel.font.withSize(12)
            messageLabel.textAlignment = .center
            messageLabel.backgroundColor = UIColor.clear
            
            let title: NSMutableAttributedString
            
            if isUpdating {
                title = NSMutableAttributedString(string: "Updating ...")
            } else {
                if let oldestUpdateDate = addresses.sorted(by: {
                    guard let date0 = $0.lastUpdate, let date1 = $1.lastUpdate else {
                        return false
                    }
                    
                    return date0 < date1
                }).first?.lastUpdate {
                    title = NSMutableAttributedString(string: "\(updateDateFormatter.string(from: oldestUpdateDate))\n")
                } else {
                    title = NSMutableAttributedString(string: "")
                }
                
                if let unreadTransactions = fetchedResultsController?.fetchedObjects?.filter({ $0.isUnread }), unreadTransactions.count > 0 {
                    title.append(NSAttributedString(string: "\(unreadTransactions.count) unread", attributes: [
                        NSAttributedStringKey.foregroundColor : UIColor.gray
                        ]))
                } else {
                    messageLabel.numberOfLines = 1
                }
            }
            
            messageLabel.attributedText = title
            messageLabel.sizeToFit()
            
            return UIBarButtonItem(customView: messageLabel)
        }
    }
    
    // MARK: UI Updating
    @objc func startUpdateTimer() {
        guard updateTimer == nil else {
            // timer already running
            return
        }
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { _ in
            self.updateToolbar()
        })
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.setObserver(self, selector: #selector(stopUpdateTimer), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
        notificationCenter.setObserver(self, selector: #selector(startUpdateTimer), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        log.debug("Started timer for TransactionTable with 60 second intervall.")
    }
    
    @objc func stopUpdateTimer() {
        guard updateTimer != nil else {
            // no timer set
            return
        }
        
        updateTimer?.invalidate()
        updateTimer = nil
        log.debug("Stopped timer for TransactionTable.")
    }
    
    // MARK: UI Modification
    @objc private func toggleShowsExchangeValue() {
        showsExchangeValue = !showsExchangeValue
    }
    
    @objc private func toggleIsFilterActive() {
        isFilterActive = !isFilterActive
    }

    // MARK: Content Interaction
    @objc private func updateAddresses() {
        isUpdating = true
        
        for (index, address) in addresses.enumerated() {
            var updateCompletion: (() -> Void)? = nil
            
            if index == addresses.count-1 {
                updateCompletion = {
                    self.refreshControl?.endRefreshing()
                    self.isUpdating = false
                }
            }
            
            address.update(completion: updateCompletion)
        }
    }
    
    @objc private func setIsUnread() {
        guard let selectedTransactions = selectedTransactions else {
            return
        }
        
        let isUnread = !selectedTransactions.contains(where: { $0.isUnread })
        
        for transaction in selectedTransactions {
            do {
                try transaction.setIsUnread(state: isUnread)
            } catch {
                // present error
            }
        }
        
        self.isEditing = false
    }
    
    @objc private func setIsInvestment() {
        guard let selectedTransactions = selectedTransactions else {
            return
        }
        
        let isInvestment = !selectedTransactions.contains(where: { $0.isInvestment })
        
        for transaction in selectedTransactions {
            do {
                try transaction.setIsInvestment(state: isInvestment)
            } catch {
                // present error
            }
        }
        
        self.isEditing = false
    }

    @objc private func showExchangeValueActionSheet() {
        guard let selectedTransactions = selectedTransactions else {
            return
        }
        
        if selectedTransactions.count == 1 && !selectedTransactions.contains(where: { $0.hasUserExchangeValue }) {
            showExchangeValueInputAlert()
        } else {
            let alertController = UIAlertController(title: (selectedTransactions.count > 1 ? "Selected \(selectedTransactions.count) transactions" : nil), message: nil, preferredStyle: .actionSheet)
        
            alertController.addAction(UIAlertAction(title: "Set \(selectedTransactions.count > 1 ? "distributed" : "") exchange value", style: .default, handler: { _ in
                self.showExchangeValueInputAlert()
            }))
            
            if selectedTransactions.contains(where: { $0.hasUserExchangeValue }) {
                alertController.addAction(UIAlertAction(title: "Reset exchange value", style: .destructive, handler: { _ in
                    for transaction in selectedTransactions {
                        do {
                            try transaction.resetUserExchangeValue()
                        } catch {
                            // present error
                        }
                    }
                    
                    self.isEditing = false
                }))
            }
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    }
    
    @objc private func showExchangeValueInputAlert() {
        guard let selectedTransactions = self.selectedTransactions else {
            return
        }
        
        let alertController = UIAlertController(title: "Exchange Value", message: nil, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { alertAction in
            let valueField = alertController.textFields![0]
            
            guard let totalValueString = valueField.text?.trimmingCharacters(in: .whitespacesAndNewlines), let totalExchangeValue = Double(totalValueString) else {
                return
            }
            
            let totalAmount = selectedTransactions.compactMap({ $0.totalAmount }).reduce(0, +)
            
            for transaction in selectedTransactions {
                do {
                    let value = totalExchangeValue / totalAmount * transaction.totalAmount
                    try transaction.setUserExchangeValue(value: value)
                } catch {
                    // present error
                }
            }
            
            self.isEditing = false
        })
        
        saveAction.isEnabled = false
        saveExchangeValueAction = saveAction
        
        alertController.addTextField(configurationHandler: { textField in
            textField.delegate = self
            textField.keyboardType = .decimalPad
            textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
            
            let totalExchangeValue = selectedTransactions.compactMap({ $0.exchangeValue }).reduce(0, +)
            textField.placeholder = self.currencyFormatter.getCurrencyFormatting(for: totalExchangeValue, currency: self.portfolioManager.quoteCurrency)
        })
        
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - TextField Delegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let decimalSeperator = NumberFormatter().decimalSeparator!
        
        if string.count == 1 {
            if textField.text?.range(of: decimalSeperator) != nil {
                if string == decimalSeperator {
                    return false
                }
                
                if let subStrings = textField.text?.split(separator: Character(decimalSeperator)) {
                    let decimalDigits: String
                    
                    if subStrings.count == 2 {
                        decimalDigits = subStrings[1] + string
                    } else {
                        decimalDigits = string
                    }
                    
                    if decimalDigits.count > portfolioManager.quoteCurrency.decimalDigits {
                        return false
                    }
                }
                
                return true
            } else {
                return true
            }
        } else {
            let char = string.cString(using: String.Encoding.utf8)!
            let isBackSpace = strcmp(char, "\\b")
            
            if (isBackSpace == -92) {
                // backspace pressed
                return true
            } else {
                // pasted text
                return false
            }
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let newValueString = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !newValueString.isEmpty {
            saveExchangeValueAction.isEnabled = true
        } else {
            saveExchangeValueAction.isEnabled = false
        }
    }
    
    // MARK: - Filter Delegate
    func didChangeTransactionType(type: TransactionType) {
        filter.transactionType = type
    }
    
    func didChangeIsUnread(state: Bool) {
        filter.isUnread = state
    }
    
    func didChangeIsError(state: Bool) {
        filter.isError = state
    }
    
    func didChangeHasUserExchangeValue(state: Bool) {
        filter.hasUserExchangeValue = state
    }
    
    func didResetFilter() {
        isFilterActive = false
        filter = Filter()
    }
    
    // MARK: - TableView Data Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections, sections.count > 0 {
            return sections[section].numberOfObjects
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let transaction = fetchedResultsController!.object(at: indexPath)
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "TransactionCell")
        
//        let cell = tableView.dequeueReusableCell(withIdentifier: "transactionCell", for: indexPath) as! TransactionCell
//        cell.configure(transaction: transaction)
        
        if showsExchangeValue, let exchangeValue = transaction.exchangeValue {
            cell.textLabel?.text = currencyFormatter.getCurrencyFormatting(for: exchangeValue, currency: transaction.owner!.quoteCurrency)
        } else {
            cell.textLabel?.text = currencyFormatter.getCurrencyFormatting(for: transaction.totalAmount, currency: transaction.owner!.blockchain)
        }
        
        cell.detailTextLabel?.text = dateFormatter.string(from: transaction.date! as Date)

        if transaction.isOutbound {
            cell.textLabel?.textColor = UIColor.red
        } else {
            cell.textLabel?.textColor = UIColor.green
        }
    
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchedResultsController?.sections, sections.count > 0 {
            return sections[section].name
        } else {
            return nil
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetchedResultsController?.sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return fetchedResultsController?.section(forSectionIndexTitle: title, at: index) ?? 0
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isEditing {
            updateToolbar()
        } else {
            let transactionDetailViewController = viewFactory.makeTransactionDetailViewController(for: fetchedResultsController!.object(at: indexPath))
            navigationController?.pushViewController(transactionDetailViewController, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isEditing {
            updateToolbar()
        }
    }
   
}
