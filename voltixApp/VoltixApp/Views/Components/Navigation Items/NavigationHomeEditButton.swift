//
//  NavigationHomeEditButton.swift
//  VoltixApp
//
//  Created by Amol Kumar on 2024-04-17.
//

import SwiftUI

struct NavigationHomeEditButton: View {
    let vault: Vault?
    let showVaultsList: Bool
    @Binding var isEditingVaults: Bool
    
    var body: some View {
        if showVaultsList {
            vaultsListEditButton
        } else {
            vaultDetailSettingButton
        }
    }
    
    var vaultsListEditButton: some View {
        Button {
            isEditingVaults.toggle()
        } label: {
            if isEditingVaults {
                doneButton
            } else {
                settingButton
            }
        }
    }
    
    var vaultDetailSettingButton: some View {
        NavigationLink {
            EditVaultView(vault: vault ?? Vault.example)
        } label: {
            settingButton
        }
    }
    
    var settingButton: some View {
        NavigationSettingButton()
    }
    
    var doneButton: some View {
        Text(NSLocalizedString("done", comment: ""))
            .font(.body18MenloBold)
            .foregroundColor(.neutral0)
    }
}

#Preview {
    ZStack {
        Background()
        VStack {
            NavigationHomeEditButton(vault: Vault.example, showVaultsList: true, isEditingVaults: .constant(true))
            NavigationHomeEditButton(vault: Vault.example, showVaultsList: true, isEditingVaults: .constant(false))
        }
    }
}
