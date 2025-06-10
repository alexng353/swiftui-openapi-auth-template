//
//  ProfileView.swift
//  scale
//
//  Created by Alexander Ng on 2025-04-20.
//

import SwiftUI
import KeychainAccess

struct ProfileView: View {
    @AppStorage("isSignedIn") var isSignedIn: Bool = false
    @AppStorage("user.real_name") var real_name: String = "";
    @AppStorage("user.email") var email: String = "";

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                VStack {
                    Text(real_name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.title)
                    Text(email)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Button(action: {
                    let keychain = Keychain(service: "icu.ayo.scale")
                    // TODO: banner or something
                    try? keychain.remove("auth.token")
                    isSignedIn = false
                }) {
                    Text("Sign Out")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }.padding(.horizontal)
        }
    }
}

#Preview {
    ProfileView()
}
