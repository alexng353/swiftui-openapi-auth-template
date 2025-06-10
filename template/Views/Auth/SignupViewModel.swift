//
//  SignupViewModel.swift
//  scale
//
//  Created by Alexander Ng on 2025-04-21.
//

import Foundation
import KeychainAccess

enum SignupError: Error, LocalizedError {
    case invalidEmail
    case invalidPassword
    case signupFailed
    case noToken
    case badTokenData
    case savingTokenFailed
    case unknown

    var errorDescription: String? {
        switch self {
            case .invalidEmail:
                return "The email address is invalid."
            case .invalidPassword:
                return "Your password must meet the required criteria."
            case .signupFailed:
                return "Signup failed. Please try again later."
            case .noToken:
                return "No token was received after signup."
            case .badTokenData:
                return "The token data is corrupted or invalid."
            case .savingTokenFailed:
                return "Failed to save the token to Keychain."
            case .unknown:
                return "An unknown error occurred during signup."
        }
    }
}

@MainActor
class SignupViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var realName: String = ""

    @Published var error: SignupError?
    @Published var isSigningUp: Bool = false

    func signup() async throws -> User? {
        do {
            return try await performSignup()
        } catch let signupError as SignupError {
            self.error = signupError
            return nil
        } catch {
            throw error
        }
    }

    private func performSignup() async throws -> User {
        let client = getClient()
        isSigningUp = true
        defer { isSigningUp = false }

        guard validateEmail(email) else {
            throw SignupError.invalidEmail
        }

        guard let response = try? await client.signup(
            body: .json(.init(email: email, password: password,  real_name: realName))
        ).ok else {
            throw SignupError.signupFailed
        }

        guard let plainText = try? response.body.plainText else {
            throw SignupError.noToken
        }

        guard let token = try? await String(collecting: plainText, upTo: 8192) else {
            throw SignupError.badTokenData
        }

        do {
            let keychain = Keychain(service: "icu.ayo.scale")
            try keychain.set(token, key: "auth.token")
        } catch {
            throw SignupError.savingTokenFailed
        }

        let authedClient = getClient()

        guard let userResponse = try? await authedClient.get_self().ok,
              let userJson = try? userResponse.body.json else {
            throw LoginError.unknown
        }

        return User(real_name: userJson.real_name, email: userJson.email)
    }
}

