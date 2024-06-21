//
//  CoinsGrouped.swift
//  VultisigApp
//
//  Created by Amol Kumar on 2024-03-12.
//

import Foundation

class GroupedChain {
    let id: String
    let chain: Chain
    let address: String
    var logo: String
    var count: Int
    var coins: [Coin]
    var order: Int = 0
    var totalBalanceInFiatDecimal: Decimal = 0.0

    var totalBalanceInFiatString: String {
        return totalBalanceInFiatDecimal.formatToFiat(includeCurrencySymbol: true)
    }

    var name: String {
        return chain.name
    }

    var nativeCoin: Coin {
        return coins[0]
    }

    init(chain: Chain, address: String, logo: String, count: Int = 0, coins: [Coin]) {
        self.id = chain.name + "-" + address
        self.chain = chain
        self.address = address
        self.logo = logo
        self.count = count
        self.coins = coins
        self.totalBalanceInFiatDecimal = coins.totalBalanceInFiatDecimal
    }
    
    func setOrder(_ index: Int) {
        order = index
    }
    
    static var example = GroupedChain(chain: .ethereum, address: "bc1psrjtwm7682v6nhx2...uwfgcfelrennd7pcvq", logo: "btc", count: 3, coins: [Coin.example])
}
