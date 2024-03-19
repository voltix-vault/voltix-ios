//
//  SendCryptoDetailsView.swift
//  VoltixApp
//
//  Created by Amol Kumar on 2024-03-13.
//

import OSLog
import SwiftUI

enum Field: Hashable {
    case toAddress
    case amount
    case amountInUSD
}

struct SendCryptoDetailsView: View {
    @ObservedObject var tx: SendTransaction
    @ObservedObject var utxoBtc: BitcoinUnspentOutputsService
    @ObservedObject var utxoLtc: LitecoinUnspentOutputsService
    @ObservedObject var eth: EthplorerAPIService
    @ObservedObject var thor: ThorchainService
    @ObservedObject var sol: SolanaService
    @ObservedObject var sendCryptoViewModel: SendCryptoViewModel
    @ObservedObject var coinViewModel: CoinViewModel
    let group: GroupedChain
    
    @State var toAddress = ""
    @State var amount = ""
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        ZStack {
            Background()
            view
        }
        .gesture(DragGesture())
    }
    
    var view: some View {
        VStack {
            fields
            button
        }
    }
    
    var fields: some View {
        ScrollView {
            VStack(spacing: 16) {
                coinSelector
                fromField
                toField
                amountField
                amountUSDField
                gasField
            }
            .padding(.horizontal, 16)
        }
    }
    
    var coinSelector: some View {
        TokenSelectorDropdown(tx: tx, coinViewModel: coinViewModel, group: group)
    }
    
    var fromField: some View {
        VStack(spacing: 8) {
            getTitle(for: "from")
            fromTextField
        }
    }
    
    var fromTextField: some View {
        Text(tx.fromAddress)
            .font(.body12Menlo)
            .foregroundColor(.neutral0)
            .frame(height: 48)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .background(Color.blue600)
            .cornerRadius(10)
            .lineLimit(1)
    }
    
    var toField: some View {
        VStack(spacing: 8) {
            getTitle(for: "to")
            SendCryptoAddressTextField(tx: tx, sendCryptoViewModel: sendCryptoViewModel)
                .focused($focusedField, equals: .toAddress)
        }
    }
    
    var amountField: some View {
        VStack(spacing: 8) {
            getTitle(for: "amount")
            textField
        }
    }
    
    var textField: some View {
        SendCryptoAmountTextField(
            tx: tx,
            utxoBtc: utxoBtc,
            utxoLtc: utxoLtc,
            eth: eth,
            thor: thor,
            sol: sol,
            sendCryptoViewModel: sendCryptoViewModel
        )
        .focused($focusedField, equals: .amount)
    }
    
    var amountUSDField: some View {
        VStack(spacing: 8) {
            getTitle(for: "amount(inUSD)")
            textFieldUSD
        }
    }
    
    var textFieldUSD: some View {
        SendCryptoAmountUSDTextField(
            tx: tx,
            utxoBtc: utxoBtc,
            utxoLtc: utxoLtc,
            eth: eth,
            thor: thor,
            sol: sol,
            sendCryptoViewModel: sendCryptoViewModel
        )
        .focused($focusedField, equals: .amountInUSD)
    }
    
    var gasField: some View {
        HStack {
            Text(NSLocalizedString("gas(auto)", comment: ""))
            Spacer()
            Text("\(tx.gas) \(tx.coin.feeUnit )")
        }
        .font(.body16Menlo)
        .foregroundColor(.neutral0)
    }
    
    var button: some View {
        Button {
            validateForm()
        } label: {
            FilledButton(title: "continue")
        }
        .padding(40)
    }
    
    private func getTitle(for text: String) -> some View {
        Text(NSLocalizedString(text, comment: ""))
            .font(.body14MontserratMedium)
            .foregroundColor(.neutral0)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func validateForm() {
        if sendCryptoViewModel.validateForm(tx: tx, utxoBtc: utxoBtc, utxoLtc: utxoLtc, eth: eth, sol: sol) {
            sendCryptoViewModel.moveToNextView()
        }
    }
}

#Preview {
    SendCryptoDetailsView(
        tx: SendTransaction(),
        utxoBtc: BitcoinUnspentOutputsService(),
        utxoLtc: LitecoinUnspentOutputsService(),
        eth: EthplorerAPIService(),
        thor: ThorchainService.shared,
        sol: SolanaService.shared,
        sendCryptoViewModel: SendCryptoViewModel(),
        coinViewModel: CoinViewModel(),
        group: GroupedChain.example
    )
}
