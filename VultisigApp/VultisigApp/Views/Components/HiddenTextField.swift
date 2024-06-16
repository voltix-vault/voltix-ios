//
//  HiddenTextField.swift
//  VultisigApp
//
//  Created by Amol Kumar on 2024-06-16.
//

import SwiftUI

struct HiddenTextField: View {
    let placeholder: String
    @Binding var password: String
    
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        field
    }
    
    var field: some View {
        HStack {
            textfield
            button
        }
        .frame(height: 56)
        .padding(.horizontal, 16)
        .background(Color.blue600)
        .cornerRadius(12)
    }
    
    var textfield: some View {
        ZStack {
            if isPasswordVisible {
                TextField(NSLocalizedString(placeholder, comment: ""), text: $password)
            } else {
                SecureField(NSLocalizedString(placeholder, comment: ""), text: $password)
            }
        }
        .submitLabel(.done)
        .colorScheme(.dark)
        .font(.body16Menlo)
        .foregroundColor(.neutral0)
    }
    
    var button: some View {
        Button(action: {
            withAnimation {
                isPasswordVisible.toggle()
            }
        }) {
            Image(systemName: isPasswordVisible ? "eye": "eye.slash")
                .foregroundColor(.neutral0)
        }
    }
}

#Preview {
    ZStack {
        Background()
        HiddenTextField(placeholder: "verifyPassword", password: .constant("password"))
    }
}
