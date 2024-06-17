//
//  NetworkPrompts.swift
//  VultisigApp
//
//  Created by Amol Kumar on 2024-04-16.
//

import SwiftUI

struct NetworkPrompts: View {
    @Binding var selectedNetwork: NetworkPromptType
    
    private let gridRows = [
            GridItem(.adaptive(minimum: 150))
    ]
    
    var body: some View {
        ZStack {
#if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .phone {
                phoneLayout
            } else {
                padLayout
            }
#endif
        }
    }
    
    var phoneLayout: some View {
        HStack(spacing: 12) {
            cells
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }
    
    var padLayout: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 120)), count: 3), spacing: 10){
            cells
        }
        .padding(.horizontal, 24)
    }
    
    var cells: some View {
        ForEach(NetworkPromptType.allCases, id: \.self) { network in
            getButton(network, isSelected: network==selectedNetwork)
        }
    }
    
    private func getButton(_ network: NetworkPromptType, isSelected: Bool) -> some View {
        Button {
            handleSelection(for: network)
        } label: {
            NetworkPromptCell(network: network, isSelected: isSelected)
        }
    }
    
    private func handleSelection(for network: NetworkPromptType) {
        withAnimation {
            selectedNetwork = network
        }
        
        if network == .Cellular {
            VultisigRelay.IsRelayEnabled = true
        } else {
            VultisigRelay.IsRelayEnabled = false
        }
    }
}

#Preview {
    ZStack {
        Background()
        NetworkPrompts(selectedNetwork: .constant(.WiFi))
    }
}
