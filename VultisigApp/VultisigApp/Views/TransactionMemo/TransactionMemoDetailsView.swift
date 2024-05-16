import Foundation
import OSLog
import SwiftUI

struct TransactionMemoDetailsView: View {
    @ObservedObject var tx: SendTransaction
    @ObservedObject var depositViewModel: TransactionMemoViewModel
    let group: GroupedChain
    
    @State var amount = ""
    @State var nativeTokenBalance = ""
    @State private var selectedFunctionMemoType: TransactionMemoType = .swap
    @State private var selectedContractMemoType: TransactionMemoContractType = .thorChainMessageDeposit
    
    @State private var txMemoInstance: TransactionMemoInstance = .swap(TransactionMemoSwap())
    
    var body: some View {
        ZStack {
            Background()
            view
        }
        .gesture(DragGesture())
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button {
                    hideKeyboard()
                } label: {
                    Text(NSLocalizedString("done", comment: "Done"))
                }
            }
        }
        .alert(isPresented: $depositViewModel.showAlert) {
            alert
        }
        .onChange(of: selectedFunctionMemoType) {
            switch selectedFunctionMemoType {
            case .swap:
                txMemoInstance = .swap(TransactionMemoSwap())
            case .depositSavers:
                txMemoInstance = .depositSavers(TransactionMemoDepositSavers())
            case .withdrawSavers:
                txMemoInstance = .withdrawSavers(TransactionMemoWithdrawSavers())
            case .openLoan:
                txMemoInstance = .openLoan(TransactionMemoOpenLoan())
            case .repayLoan:
                txMemoInstance = .repayLoan(TransactionMemoRepayLoan())
            case .addLiquidity:
                txMemoInstance = .addLiquidity(TransactionMemoAddLiquidity())
            case .withdrawLiquidity:
                txMemoInstance = .withdrawLiquidity(TransactionMemoWithdrawLiquidity())
            case .addTradeAccount:
                txMemoInstance = .addTradeAccount(TransactionMemoAddTradeAccount())
            case .withdrawTradeAccount:
                txMemoInstance = .withdrawTradeAccount(TransactionMemoWithdrawTradeAccount())
            case .nodeMaintenance:
                txMemoInstance = .nodeMaintenance(TransactionMemoNodeMaintenance())
            case .donateReserve:
                txMemoInstance = .donateReserve(TransactionMemoDonateReserve())
            case .migrate:
                txMemoInstance = .migrate(TransactionMemoMigrate())
            }
        }
    }
    
    var view: some View {
        VStack {
            fields
            button
        }
    }
    
    var alert: Alert {
        Alert(
            title: Text(NSLocalizedString("error", comment: "")),
            message: Text(NSLocalizedString(depositViewModel.errorMessage, comment: "")),
            dismissButton: .default(Text(NSLocalizedString("ok", comment: "")))
        )
    }
    
    var fields: some View {
        ScrollView {
            VStack(spacing: 16) {
                contractSelector
                functionSelector
                txMemoInstance.view
            }
            .padding(.horizontal, 16)
        }
    }
    
    var functionSelector: some View {
        TransactionMemoSelectorDropdown(items: .constant(TransactionMemoType.allCases), selected: $selectedFunctionMemoType)
    }
    
    var contractSelector: some View {
        TransactionMemoContractSelectorDropDown(items: .constant(TransactionMemoContractType.allCases), selected: $selectedContractMemoType)
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
    
    var button: some View {
        Button {
            Task {
                print(txMemoInstance.description)
                //await validateForm()
            }
        } label: {
            FilledButton(title: "continue")
        }
        .padding(40)
    }
    
    private func getTitle(for text: String) -> some View {
        Text(
            NSLocalizedString(text, comment: .empty)
                .replacingOccurrences(of: "Fiat", with: SettingsCurrency.current.rawValue)
        )
        .font(.body14MontserratMedium)
        .foregroundColor(.neutral0)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func getDetailsCell(for title: String, with value: String) -> some View {
        HStack {
            Text(
                NSLocalizedString(title, comment: .empty)
            )
            Spacer()
            Text(value)
        }
        .font(.body16MenloBold)
        .foregroundColor(.neutral100)
    }
    
    private func validateForm() async {
        if await depositViewModel.validateForm(tx: tx) {
            depositViewModel.moveToNextView()
        }
    }
}

#Preview {
    TransactionMemoDetailsView(
        tx: SendTransaction(),
        depositViewModel: TransactionMemoViewModel(),
        group: GroupedChain.example
    )
}