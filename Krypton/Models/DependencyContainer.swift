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
    typealias BlockchainConnector = BlockExplorer & TokenExplorer
    
    // Mark: - Singletons
    private let portfolioManager: PortfolioManager
    private let tickerDaemon: TickerDaemon
    private let blockchainDaemom: BlockchainDaemon
    private let kryptonDaemon: KryptonDaemon
    
    // Mark: - Private Properties
    private let logDataPath: URL = FileManager().urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("swiftybeaver.log")
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
    
    private var exchange: Exchange {
        return CryptoCompareService(hostURL: "https://min-api.cryptocompare.com", port: nil, credentials: nil)
    }
    
    private var exchangeRateManager: ExchangeRateManager {
        return ExchangeRateManager(context: viewContext, tickerDaemon: tickerDaemon, exchange: exchange)
    }
    
    private var taxAdviser: TaxAdviser {
        return TaxAdviser(exchangeRateManager: exchangeRateManager, currencyManager: currencyManager)
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
    
    private var colorContainer: ColorContainer {
        return ColorContainer()
    }
    
    // Mark: - Initialization
    init() throws {
        do {
            portfolioManager = try PortfolioManager(context: viewContext, currencyManager: CurrencyManager())
        } catch {
            log.error("Failed to initialize PortfolioManager singleton: \(error)")
            throw error
        }
        
        let exchange: Exchange = CryptoCompareService(hostURL: "https://min-api.cryptocompare.com", port: nil, credentials: nil)
        let blockchainConnector: BlockchainConnector = BlockchainService()
        
        tickerDaemon = TickerDaemon(exchange: exchange)
        blockchainDaemom = BlockchainDaemon(blockExplorer: blockchainConnector)
        let exchangeRateManager = ExchangeRateManager(context: viewContext, tickerDaemon: tickerDaemon, exchange: exchange)
        kryptonDaemon = KryptonDaemon(portfolioManager: portfolioManager, tickerDaemon: tickerDaemon, blockchainDaemon: blockchainDaemom, exchangeRateManager: exchangeRateManager)
    }
    
}

extension DependencyContainer: ViewControllerFactory {
    
    // Main
    func makeAccountsViewController() -> AccountsViewController {
        return AccountsViewController(viewFactory: self, kryptonDaemon: kryptonDaemon, portfolioManager: portfolioManager, tickerDaemon: tickerDaemon, currencyFormatter: currencyFormatter, taxAdviser: taxAdviser)
    }
    
    func makeWatchlistViewController() -> WatchlistViewController {
        return WatchlistViewController(portfolioManager: portfolioManager, tickerDaemon: tickerDaemon, currencyManager: currencyManager, currencyFormatter: currencyFormatter)
    }
    
    // Dashboard
    func makeDashboardViewController() -> DashboardViewController {
        return DashboardViewController(viewFactory: self, kryptonDaemon: kryptonDaemon, portfolioManager: portfolioManager, tickerDaemon: tickerDaemon, colorPalette: colorContainer)
    }
    
    func makeAnalysisChartViewController(analysisType: AnalysisType, transactionType: TransactionType) -> AnalysisChartViewController {
        return AnalysisChartViewController(portfolioManager: portfolioManager, taxAdviser: taxAdviser, anaylsisType: analysisType, transactionType: transactionType, colorPalette: colorContainer)
    }
    
    func makeInsightsViewController(analysisType: AnalysisType, transactionType: TransactionType) -> InsightsViewController {
        return InsightsViewController(portfolioManager: portfolioManager, taxAdviser: taxAdviser, currencyFormatter: currencyFormatter, comparisonDateFormatter: mediumDateFormatter, colorPalette: colorContainer, analysisType: analysisType, transactionType: transactionType)
    }
    
    // Portfolio
    func makePortfoliosViewController() -> PortfoliosViewController {
        return PortfoliosViewController(viewFactory: self, kryptonDaemon: kryptonDaemon, portfolioManager: portfolioManager, selectedPortfolio: nil, isSelector: false)
    }
    
    func makePortfolioSelectorViewController(selection: Portfolio?) -> PortfoliosViewController {
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
        return AddressDetailViewController(viewFactory: self, address: address, currencyFormatter: currencyFormatter, taxAdviser: taxAdviser)
    }
    
    func makeAddAdressViewController() -> AddAddressViewController {
        return AddAddressViewController(viewFactory: self, portfolioManager: portfolioManager, blockchains: blockchains)
    }
    
    func makeAmountByAddressViewController(for transaction: BitcoinTransaction, type: AmountByAddressType) -> AmountByAddressViewController {
        return AmountByAddressViewController(transaction: transaction, portfolioManager: portfolioManager, currencyFormatter: currencyFormatter, type: type)
    }
    
    // Transaction
    func makeTransactionsViewController(for addresses: [Address]) -> TransactionsViewController {
        return TransactionsViewController(viewFactory: self, addresses: addresses, portfolioManager: portfolioManager, searchContext: viewContext, dateFormatter: mediumDateFormatter, updateDateFormatter: updateStatusDateFormatter, currencyFormatter: currencyFormatter, taxAdviser: taxAdviser)
    }
    
    func makeTransactionDetailViewController(for transaction: Transaction) -> TransactionDetailViewController {
        return TransactionDetailViewController(viewFactory: self, transaction: transaction, kryptonDaemon: kryptonDaemon, portfolioManager: portfolioManager, tickerDaemon: tickerDaemon, blockchainDaemon: blockchainDaemom, currencyFormatter: currencyFormatter, dateFormatter: mediumDateFormatter, taxAdviser: taxAdviser)
    }
    
    // Settings
    func makeSettingsViewController() -> SettingsViewController {
        return SettingsViewController(viewFactory: self, kryptonDaemon: kryptonDaemon, portfolioManager: portfolioManager)
    }
    
    func makeLogDataViewController() -> LogDataViewController? {
        return LogDataViewController(path: logDataPath)
    }
    
    // Shared
    func makeCurrencySelector(type: CurrencyType, selection: Currency?) -> CurrencySelectorViewController {
        return CurrencySelectorViewController(type: type, selection: selection, currencyManager: currencyManager)
    }
    
    func makeFilterViewController(showsAdvancedProperties: Bool, isAddressSelector: Bool) -> FilterViewController {
        return FilterViewController(portfolioManager: portfolioManager, showsAdvancedProperties: showsAdvancedProperties, isSelector: isAddressSelector)
    }
    
}
