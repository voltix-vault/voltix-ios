//
//  BlockchairService.swift
//  VoltixApp
//
//  Created by Enrique Souza Soares on 17/03/2024.
//

import Foundation

@MainActor
public class BlockchairService: ObservableObject {
	
	static let shared = BlockchairService()
	private init(){}
	
	@Published var blockchairData: Blockchair?
	@Published var errorMessage: String?
	
	public func fetchBlockchairData(for address: String, coinName: String) async {
		guard let url = URL(string: Endpoint.blockchairDashboard(address, coinName)) else {
			print("Invalid URL")
			return
		}
		
		do {
			let (data, _) = try await URLSession.shared.data(from: url)
			let decoder = JSONDecoder()
			let decodedData = try decoder.decode(BlockchairResponse.self, from: data)
			if let blockchairData = decodedData.data[address] {
				print(blockchairData)
				self.blockchairData = blockchairData
			}
		} catch let DecodingError.dataCorrupted(context) {
			print("Data corrupted: \(context)")
			self.errorMessage = "Data corrupted: \(context)"
		} catch let DecodingError.keyNotFound(key, context) {
			print("Key '\(key)' not found: \(context.debugDescription)")
			self.errorMessage = "Key '\(key)' not found: \(context.debugDescription)"
		} catch let DecodingError.valueNotFound(value, context) {
			print("Value '\(value)' not found: \(context.debugDescription)")
			self.errorMessage = "Value '\(value)' not found: \(context.debugDescription)"
		} catch let DecodingError.typeMismatch(type, context) {
			print("Type '\(type)' mismatch: \(context.debugDescription)")
			self.errorMessage = "Type '\(type)' mismatch: \(context.debugDescription)"
		} catch {
			print("Error: \(error.localizedDescription)")
			self.errorMessage = "Error: \(error.localizedDescription)"
		}
	}
}

