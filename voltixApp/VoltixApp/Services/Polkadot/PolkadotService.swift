//
//  PolkadotService.swift
//  VoltixApp
//
//  Created by Enrique Souza Soares on 28/04/24.
//

import Foundation
import BigInt

class PolkadotService: RpcService {
    static let rpcEndpoint = Endpoint.polkadotServiceRpc
    static let shared = PolkadotService(rpcEndpoint)
    
    private var cachePolkadotBalance: [String: (data: BigInt, timestamp: Date)] = [:]
    
    private func fetchBalance(address: String) async throws -> BigInt {
        let cacheKey = "polkadot-\(address)-balance"
        if let cachedData: BigInt = await Utils.getCachedData(cacheKey: cacheKey, cache: cachePolkadotBalance, timeInSeconds: 60*5) {
            return cachedData
        }
        
        let body = ["key": address]
        do {
            let requestBody = try JSONEncoder().encode(body)
            let responseBodyData = try await Utils.asyncPostRequest(urlString: Endpoint.polkadotServiceBalance, headers: [:], body: requestBody)
            
            if let balance = Utils.extractResultFromJson(fromData: responseBodyData, path: "data.account.balance") as? String {
                let decimalBalance = (Decimal(string: balance) ?? Decimal.zero) * pow(10, 10)
                let bigIntResult = decimalBalance.description.toBigInt()
                self.cachePolkadotBalance[cacheKey] = (data: bigIntResult, timestamp: Date())
                return bigIntResult
            }
        } catch {
            print("PolkadotService > fetchBalance > Error encoding JSON: \(error)")
            return BigInt.zero
        }
        
        return BigInt.zero
    }
    
    private func fetchNonce(address: String) async throws -> BigInt {
        return try await intRpcCall(method: "system_accountNextIndex", params: [address])
    }
    
    private func fetchBlockHash() async throws -> String {
        return try await strRpcCall(method: "chain_getBlockHash", params: [])
    }
    
    private func fetchBlockHeader() async throws -> BigInt {
        return try await sendRPCRequest(method: "chain_getHeader", params: []) { result in
            guard let resultDict = result as? [String: Any] else {
                throw RpcServiceError.rpcError(code: 500, message: "Error to convert the RPC result to Dictionary")
            }

            guard let numberString = resultDict["number"] as? String else {
                throw RpcServiceError.rpcError(code: 404, message: "Block number not found in the response")
            }

            guard let bigIntNumber = BigInt(numberString.stripHexPrefix(), radix: 16) else {
                throw RpcServiceError.rpcError(code: 500, message: "Error to convert block number to BigInt")
            }
            return bigIntNumber
        }
    }
    
    func broadcastTransaction(hex: String) async throws -> String {
        let hexWithPrefix = hex.hasPrefix("0x") ? hex : "0x\(hex)"
        return try await strRpcCall(method: "eth_sendRawTransaction", params: [hexWithPrefix])
    }
    
    func getBalance(coin: Coin) async throws ->(rawBalance: String,priceRate: Double){
        // Start fetching all information concurrently
        let cryptoPrice = await CryptoPriceService.shared.getPrice(priceProviderId: coin.priceProviderId)
        var rawBalance = ""
        do{
            if coin.isNativeToken {
                rawBalance = String(try await fetchBalance(address: coin.address))
            } else {
                //TODO: Implement for tokens
            }
        } catch {
            print("getBalance:: \(error.localizedDescription)")
            throw error
        }
        return (rawBalance,cryptoPrice)
    }
    
    func getGasInfo(fromAddress: String) async throws -> (recentBlockHash: String, currentBlockNumber: BigInt, nonce: Int64) {
        async let recentBlockHash = fetchBlockHash()
        async let nonce = fetchNonce(address: fromAddress)
        async let currentBlockNumber = fetchBlockHeader()
        return (try await recentBlockHash, try await currentBlockNumber, Int64(try await nonce))
    }
}
