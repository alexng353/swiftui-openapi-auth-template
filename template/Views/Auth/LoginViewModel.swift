//
//  LoginViewModel.swift
//  scale
//
//  Created by Alexander Ng on 2025-04-21.
//

import Foundation
import KeychainAccess

enum LoginError: Error, LocalizedError {
    case loginRequestFailed
    case badPassword
    case userNotFound
    case savingTokenFailed
    case noToken
    case badTokenData
    case unknown

    var errorDescription: String? {
        switch self {
            case .loginRequestFailed:
                return "The login request failed. Please try again."
            case .badPassword:
                return "Incorrect password. Please try again."
            case .userNotFound:
                return "User not found. Check your username."
            case .savingTokenFailed:
                return "Could not save the login token."
            case .noToken:
                return "Login token is missing."
            case .badTokenData:
                return "The token data is invalid."
            case .unknown:
                return "An unknown error has occurred."
        }
    }
}

struct User: Codable {
    var real_name: String
    var email: String
}

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var error: LoginError?
    @Published var isLoggingIn: Bool = false

    func login() async throws -> User? {
        do {
            return try await performLogin()
        } catch let loginError as LoginError {
            self.error = loginError
            return nil
        } catch {
            throw error
        }
    }

    private func performLogin() async throws -> User {
        let client = getClient()
        isLoggingIn = true
        defer { isLoggingIn = false }

        guard let response = try? await client.login(
            body: .json(.init(email: email, password: password))
        ) else {
            throw LoginError.loginRequestFailed
        }

        guard let ok = try? response.ok else {
            if (try? response.notFound) != nil {
                throw LoginError.userNotFound
            } else if (try? response.unauthorized) != nil {
                throw LoginError.badPassword
            }
            print("Unknown error or unexpected response")
            throw LoginError.unknown
        }

        guard let plainText = try? ok.body.plainText else {
            throw LoginError.noToken
        }

        guard let token = try? await String(collecting: plainText, upTo: 8192) else {
            throw LoginError.badTokenData
        }

        do {
            let keychain = Keychain(service: "icu.ayo.scale")
            try keychain.set(token, key: "auth.token")
        } catch {
            throw LoginError.savingTokenFailed
        }

        let authedClient = getClient()
        guard let userResponse = try? await authedClient.get_self().ok,
              let userJson = try? userResponse.body.json else {
            throw LoginError.unknown
        }

        return User(real_name: userJson.real_name, email: userJson.email)
    }
}
