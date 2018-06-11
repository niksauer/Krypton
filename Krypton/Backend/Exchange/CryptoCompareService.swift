//
//  CryptoCompareService.swift
//  Krypton
//
//  Created by Niklas Sauer on 11.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import NetworkKit

struct CryptoCompareService: Service {
    
    struct ExchangeRate: Codable {
        let value: Double
    }
    
    // MARK: - Service
    typealias PrimaryResource = ExchangeRate

    let client: JSONAPIClient
    
    init(hostname: String, port: Int?, credentials: APICredentialStore?) {
        self.client = JSONAPIClient(hostname: hostname, port: port, basePath: "data", credentials: nil)
    }
    
    // MARK: - Public Methods
    func getCurrentExchangeRate(for currencyPair: CurrencyPair, completion: @escaping (ExchangeRate?, Error?) -> Void) {
        client.makeGETRequest(params: [
            "fsym": currencyPair.base.code,
            "tsyms": currencyPair.quote.code,
        ]) { result in
            print(result)
        }
    }

}
