//
//  RPCAuth.swift
//  Pay Join
//
//  Created by Peter Denton on 2/11/24.
//

import Foundation
import CryptoKit

class RPCAuth {
 
    private func generateSalt() -> String? {
        // Generates 16 random bytes, return as hex string.
         var bytes = [UInt8](repeating: 0, count: 16)
         let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

         guard result == errSecSuccess else {
             print("Problem generating random bytes")
             return nil
         }
        
        return Data(bytes).hex
    }

    private func generatePassword() -> String? {
        // Create 32 byte b64 password.
        var bytes = [UInt8](repeating: 0, count: 32)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        guard result == errSecSuccess else {
            print("Problem generating random bytes")
            return nil
        }
        
        return Data(bytes).urlSafeB64String
    }

    private func passwordToHmac(salt: String, password: String) -> String {
        let key = SymmetricKey(data: Data(salt.utf8))
        let authenticationCode = HMAC<SHA256>.authenticationCode(for: Data(password.utf8), using: key)
        return authenticationCode.compactMap { String(format: "%02x", $0) }.joined()
    }

    func generateCreds(username: String, password: String?) -> (rpcAuth: String, password: String)? {
        guard let salt = generateSalt() else { return nil }
        guard let password = password ?? generatePassword() else { return nil }
        let passwordHmac = passwordToHmac(salt: salt, password: password)
        return ("rpcauth=\(username):\(salt)$\(passwordHmac)", password)
    }
}
