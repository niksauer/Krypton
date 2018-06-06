//
//  DependencyContainer.swift
//  Krypton
//
//  Created by Niklas Sauer on 05.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import CoreData

struct DependencyContainer {
    
    // Mark: - Singletons
    private let kryptonDaemon: KryptonDaemon
    private let portfolioManager: PortfolioManager
    private let tickerDaemon: TickerDaemon = TickerDaemon.shared
    private let blockchainDaemom: BlockchainDaemon
    
    // Mark: - Private Properties
    private let viewContext: NSManagedObjectContext = CoreDataStack.shared.viewContext
    
    private var blockchains: [Blockchain] {
        return Blockchain.allValues as! [Blockchain]
    }
    
    private var currencyManager: CurrencyManager {
        return CurrencyManager()
    }

    private var currencyFormatter: CurrencyFormatter {
        return CurrencyFormatter()
    }
    
    private var exchangeRateManager: ExchangeRateManager {
        return ExchangeRateManager(context: viewContext, tickerDaemon: tickerDaemon)
    }
    
    private var mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private var updateStatusDateFormatter: DateFormatter {
        return UpdateStatusDateFormatter()
    }
    
    // Mark: - Initialization
    init() throws {
        do {
            portfolioManager = try PortfolioManager(context: viewContext, currencyManager: CurrencyManager())
        } catch {
            log.error("Failed to initialize PortfolioManager singleton: \(error)")
            throw error
        }
        
        blockchainDaemom = BlockchainDaemon()
        kryptonDaemon = KryptonDaemon(portfolioManager: portfolioManager, tickerDaemon: tickerDaemon, blockchainDaemon: blockchainDaemom)
    }
    
}

extension DependencyContainer: ViewControllerFactory {
    
    // Main
    func makeAccountsViewController() -> AccountsViewController {
        return AccountsViewController(viewFactory: self, kryptonDaemon: kryptonDaemon, portfolioManager: portfolioManager, tickerDaemon: tickerDaemon, currencyFormatter: currencyFormatter)
    }
    
    func makeWatchlistViewController() -> WatchlistViewController {
        return WatchlistViewController(portfolioManager: portfolioManager, tickerDaemon: tickerDaemon, currencyManager: currencyManager, currencyFormatter: currencyFormatter)
    }
    
    func makeDashboardViewController() -> DashboardViewController {
        return DashboardViewController(viewFactory: self, kryptonService: kryptonDaemon, portfolioManager: portfolioManager, tickerDaemon: tickerDaemon, currencyFormatter: currencyFormatter)
    }
    
    // Portfolio
    func makePortfoliosViewController() -> PortfoliosViewController {
        return PortfoliosViewController(viewFactory: self, kryptonDaemon: kryptonDaemon, portfolioManager: portfolioManager, selectedPortfolio: nil, isSelector: false)
    }
    
    func makePortfolioSelectionViewController(selection: Portfolio?) -> PortfoliosViewController {
        return PortfoliosViewController(viewFactory: self, kryptonDaemon: kryptonDaemon, portfolioManager: portfolioManager, selectedPortfolio: selection, isSelector: true)
    }
    
    func makeAddPortfolioViewController() -> AddPortfolioViewController {
        return AddPortfolioViewController(portfolioManager: portfolioManager)
    }
    
    func makePortfolioDetailViewController(for portfolio: Portfolio) -> PortfolioDetailViewController {
        return PortfolioDetailViewController(viewFactory: self, portfolio: portfolio, portfolioManager: portfolioManager)
    }
    
    // Address
    func makeAddressDetailViewController(for address: Address) -> AddressDetailViewController {
        return AddressDetailViewController(viewFactory: self, address: address, currencyFormatter: currencyFormatter)
    }
    
    func makeAddAdressViewController() -> AddAddressViewController {
        return AddAddressViewController(viewFactory: self, portfolioManager: portfolioManager, blockchains: blockchains)
    }
    
    func makeAmountByAddressViewController(for transaction: Transaction) -> AmountByAddressViewController {
        return AmountByAddressViewController(transaction: transaction, portfolioManager: portfolioManager, currencyFormatter: currencyFormatter)
    }
    
    // Transaction
    func makeTransactionsViewController(for addresses: [Address]) -> TransactionsViewController {
        return TransactionsViewController(viewFactory: self, addresses: addresses, portfolioManager: portfolioManager, searchContext: viewContext, dateFormatter: mediumDateFormatter, updateDateFormatter: updateStatusDateFormatter, currencyFormatter: currencyFormatter)
    }
    
    func makeTransactionDetailViewController(for transaction: Transaction) -> TransactionDetailViewController {
        return TransactionDetailViewController(viewFactory: self, transaction: transaction, kryptonDaemon: kryptonDaemon, portfolioManager: portfolioManager, tickerDaemon: tickerDaemon, blockchainDaemon: blockchainDaemom, currencyFormatter: currencyFormatter, dateFormatter: mediumDateFormatter)
    }
    
    // Settings
    func makeSettingsViewController() -> SettingsViewController {
        return SettingsViewController(viewFactory: self, kryptonDaemon: kryptonDaemon, portfolioManager: portfolioManager)
    }
    
    // Shared
    func makeCurrencySelector(type: CurrencyType, selection: Currency?) -> CurrencySelectorViewController {
        return CurrencySelectorViewController(type: type, selection: selection, currencyManager: currencyManager)
    }
    
    func makeFilterViewController() -> FilterViewController {
        return FilterViewController(portfolioManager: portfolioManager)
    }
    
}
