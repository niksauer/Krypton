//
//  EthplorerService.swift
//  Krypton
//
//  Created by Niklas Sauer on 14.08.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import Foundation
import NetworkKit

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
            completion(result.instance, result.error)
        }
    }

    func fetchTokenOperations(for address: EthereumAddress, token: Token, type: TokenOperationType, completion: @escaping ([TokenOperationPrototype]?, Error?) -> Void) {
        client.makeGETRequest(to: "/getAddressHistory/\(address.identifier!)", params: [
            "apiKey": apiKey,
            "token": token.address,
            "type": type.rawValue,
            "limit:": "10"
        ]) { result in
            let result = self.decode([EthplorerTokenOperation].self, from: result, at: "operations")
            completion(result.instance, result.error)
        }
    }
   
}
