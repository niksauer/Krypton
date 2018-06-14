//
//  EthplorerService.swift
//  Krypton
//
//  Created by Niklas Sauer on 14.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation
import NetworkKit

struct EthplorerToken: TokenProtoype {
    let balance: Double
    let address: String
    let name: String
    let symbol: String
    let decimalDigits: Int
}

extension EthplorerToken: Decodable {
    enum CodingKeys: String, CodingKey {
        case tokenInfo
        case balance
    }
    
    enum TokenInfoKeys: String, CodingKey {
        case address
        case name
        case symbol
        case decimals
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let tokenInfo = try values.nestedContainer(keyedBy: TokenInfoKeys.self, forKey: .tokenInfo)
        
        let rawBalance = try values.decode(Double.self, forKey: .balance)
        
        address = try tokenInfo.decode(String.self, forKey: .address)
        name = try tokenInfo.decode(String.self, forKey: .name)
        symbol = try tokenInfo.decode(String.self, forKey: .symbol)
        
        do {
            decimalDigits = try tokenInfo.decode(Int.self, forKey: .decimals)
        } catch {
            let decimalsString = try tokenInfo.decode(String.self, forKey: .decimals)
            
            guard let decimals = Int(decimalsString) else {
                throw error
            }
            
            self.decimalDigits = decimals
        }
        
        balance = rawBalance * (pow(10, -Double(decimalDigits)))
    }
}

struct EthplorerService: JSONService, EthereumTokenExplorer {

    // MARK: - Service
    let client: JSONAPIClient
    
    init() {
        self.init(hostURL: "http://api.ethplorer.io", port: nil, credentials: nil)
    }
    
    init(hostURL: String, port: Int?, credentials: APICredentialStore?) {
        self.client = JSONAPIClient(hostURL: hostURL, port: port, basePath: nil, credentials: credentials)
    }
    
    // MARK: - Private Properties
    private let apiKey = "freekey"
    
    // MARK: - EthereumTokenExplorer
    func fetchTokens(for address: EthereumAddress, completion: @escaping ([TokenProtoype]?, Error?) -> Void) {
        client.makeGETRequest(to: "/getAddressInfo/\(address.identifier!)", params: [
            "apiKey": apiKey,
        ]) { result in
            let result = self.decode([EthplorerToken].self, from: result, at: "tokens")
            
            guard let tokens = result.instance else {
                completion(nil, result.error!)
                return
            }
            
            completion(tokens, nil)
        }
    }
    
//    // MARK: - Public Methods
//    func getInfo(contractAddress: String) {
//        client.makeGETRequest(to: "getTokenInfo", params: [
//            "apiKey": apiKey,
//            "address": contractAddress
//        ]) { result in
//
//        }
//    }
//
//    func getTokenBalance(for address: EthereumAddress, contractAddress: String) {
//        client.makeGETRequest(to: "getAddressHistory", params: [
//            "apiKey": apiKey,
//            "address": address.identifier!,
//            "token": contractAddress,
//            "type": "transfer",
//            "limit:": "10"
//        ]) { result in
//
//        }
//    }
   
}
