//
//  KeysignPayload.swift
//  VultisigApp
//

import Foundation
import BigInt
import WalletCore

struct KeysignMessage: Codable, Hashable {
    let sessionID: String
    let serviceName: String
    let payload: KeysignPayload
    let encryptionKeyHex: String
    let useVultisigRelay: Bool
}

enum BlockChainSpecific: Codable, Hashable {
    case UTXO(byteFee: BigInt, sendMaxAmount: Bool) // byteFee
    case Ethereum(maxFeePerGasWei: BigInt, priorityFeeWei: BigInt, nonce: Int64, gasLimit: BigInt) // maxFeePerGasWei, priorityFeeWei, nonce , gasLimit
    case THORChain(accountNumber: UInt64, sequence: UInt64, fee: UInt64)
    case MayaChain(accountNumber: UInt64, sequence: UInt64)
    case Cosmos(accountNumber: UInt64, sequence: UInt64, gas: UInt64)
    case Solana(recentBlockHash: String, priorityFee: BigInt) // priority fee is in microlamports
    case Sui(referenceGasPrice: BigInt, coins: [[String:String]])
    case Polkadot(recentBlockHash: String, nonce: UInt64, currentBlockNumber: BigInt, specVersion: UInt32, transactionVersion: UInt32, genesisHash: String)
    
    var gas: BigInt {
        switch self {
        case .UTXO(let byteFee, _):
            return byteFee
        case .Ethereum(let baseFee, let priorityFeeWei, _, _):
            return baseFee + priorityFeeWei
        case .THORChain(_, _, let fee):
            return fee.description.toBigInt()
        case .MayaChain:
            return MayaChainHelper.MayaChainGas.description.toBigInt() //Maya uses 10e10
        case .Cosmos(_,_,let gas):
            return gas.description.toBigInt()
        case .Solana:
            return SolanaHelper.defaultFeeInLamports
        case .Sui(let referenceGasPrice, _):
            return referenceGasPrice
        case .Polkadot:
            return PolkadotHelper.defaultFeeInPlancks
        }
    }

    var fee: BigInt {
        switch self {
        case .Ethereum(let baseFee, let priorityFeeWei, _, let gasLimit):
            return (baseFee + priorityFeeWei) * gasLimit
        case .UTXO, .THORChain, .MayaChain, .Cosmos, .Solana, .Sui, .Polkadot:
            return gas
        }
    }
}

struct KeysignPayload: Codable, Hashable {
    
    let coin: Coin
    // only toAddress is required , from Address is our own address
    let toAddress: String
    let toAmount: BigInt
    let chainSpecific: BlockChainSpecific
    
    // for UTXO chains , often it need to sign multiple UTXOs at the same time
    // here when keysign , the main device will only pass the utxo info to the keysign device
    // it is up to the signing device to get the presign keyhash , and sign it with the main device
    let utxos: [UtxoInfo]
    let memo: String? // optional memo
    let swapPayload: SwapPayload?
    let approvePayload: ERC20ApprovePayload?
    let vaultPubKeyECDSA: String
    let vaultLocalPartyID: String
    
    init(coin: Coin, toAddress: String, toAmount: BigInt, chainSpecific: BlockChainSpecific, utxos: [UtxoInfo], memo: String?, swapPayload: SwapPayload?, approvePayload: ERC20ApprovePayload? = nil, vaultPubKeyECDSA: String, vaultLocalPartyID: String) {
        self.coin = coin
        self.toAddress = toAddress
        self.toAmount = toAmount
        self.chainSpecific = chainSpecific
        self.utxos = utxos
        self.memo = memo
        self.swapPayload = swapPayload
        self.approvePayload = approvePayload
        self.vaultPubKeyECDSA = vaultPubKeyECDSA
        self.vaultLocalPartyID = vaultLocalPartyID
    }

    var toAmountString: String {
        let decimalAmount = Decimal(string: toAmount.description) ?? Decimal.zero
        let power = Decimal(sign: .plus, exponent: -coin.decimals, significand: 1)
        return "\(decimalAmount * power) \(coin.ticker)"
    }

    func getKeysignMessages(vault: Vault) throws -> [String] {
        var messages: [String] = []

        if let approvePayload {
            let swaps = THORChainSwaps(vaultHexPublicKey: vault.pubKeyECDSA, vaultHexChainCode: vault.hexChainCode)
            messages += try swaps.getPreSignedApproveImageHash(approvePayload: approvePayload, keysignPayload: self)
        }

        if let swapPayload {
            let incrementNonce = approvePayload != nil
            switch swapPayload {
            case .thorchain(let payload):
                let swaps = THORChainSwaps(vaultHexPublicKey: vault.pubKeyECDSA, vaultHexChainCode: vault.hexChainCode)
                messages += try swaps.getPreSignedImageHash(swapPayload: payload, keysignPayload: self, incrementNonce: incrementNonce)
            case .oneInch(let payload):
                let swaps = OneInchSwaps(vaultHexPublicKey: vault.pubKeyECDSA, vaultHexChainCode: vault.hexChainCode)
                messages += try swaps.getPreSignedImageHash(payload: payload, keysignPayload: self, incrementNonce: incrementNonce)
            case .mayachain:
                break // No op - Regular transaction with memo
            }
        }

        if !messages.isEmpty {
            return messages
        }

        switch coin.chain {
        case .bitcoin, .bitcoinCash, .litecoin, .dogecoin, .dash:
            let utxoHelper = UTXOChainsHelper(coin: coin.chain.coinType, vaultHexPublicKey: vault.pubKeyECDSA, vaultHexChainCode: vault.hexChainCode)
            return try utxoHelper.getPreSignedImageHash(keysignPayload: self)
        case .ethereum, .arbitrum, .base, .optimism, .polygon, .avalanche, .bscChain, .blast, .cronosChain, .zksync:
            if coin.isNativeToken {
                let helper = EVMHelper.getHelper(coin: coin.toCoinMeta())
                return try helper.getPreSignedImageHash(keysignPayload: self)
            } else {
                let helper = ERC20Helper.getHelper(coin: coin)
                return try helper.getPreSignedImageHash(keysignPayload: self)
            }
        case .thorChain:
            return try THORChainHelper.getPreSignedImageHash(keysignPayload: self)
        case .mayaChain:
            return try MayaChainHelper.getPreSignedImageHash(keysignPayload: self)
        case .solana:
            return try SolanaHelper.getPreSignedImageHash(keysignPayload: self)
        case .sui:
            return try SuiHelper.getPreSignedImageHash(keysignPayload: self)
        case .gaiaChain:
            return try ATOMHelper().getPreSignedImageHash(keysignPayload: self)
        case .kujira:
            return try KujiraHelper().getPreSignedImageHash(keysignPayload: self)
        case .polkadot:
            return try PolkadotHelper.getPreSignedImageHash(keysignPayload: self)
        case .dydx:
            return try DydxHelper().getPreSignedImageHash(keysignPayload: self)
        }
    }
    
    static let example = KeysignPayload(coin: Coin.example, toAddress: "toAddress", toAmount: 100, chainSpecific: BlockChainSpecific.UTXO(byteFee: 100, sendMaxAmount: false), utxos: [], memo: "Memo", swapPayload: nil, vaultPubKeyECDSA: "12345", vaultLocalPartyID: "iPhone-100")
}
