//
//  Extensions.swift
//  Pay Join
//
//  Created by Peter Denton on 2/11/24.
//

import Foundation

public extension Data {
    var hex: String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
    
    var urlSafeB64String: String {
        return self.base64EncodedString().replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "+", with: "-")
    }
}

public extension String {
    var noWhiteSpace: String {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
}


public extension Double {
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    var avoidNotation: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 8
        numberFormatter.numberStyle = .decimal
        numberFormatter.locale = Locale(identifier: "en_US")
        return numberFormatter.string(for: self) ?? ""
    }
    
    var btcBalanceWithSpaces: String {
        var btcBalance = abs(self.rounded(toPlaces: 8)).avoidNotation
        if !btcBalance.contains(".") {
            btcBalance += ".0"
        }
        
        if self == 0.0 {
            btcBalance = "0.00 000 000"
        } else {
            var decimalLocation = 0
            var btcBalanceArray:[String] = []
            var digitsPastDecimal = 0
                        
            for (i, c) in btcBalance.enumerated() {
                btcBalanceArray.append("\(c)")
                if c == "." {
                    decimalLocation = i
                }
                if i > decimalLocation {
                    digitsPastDecimal += 1
                }
            }
            
            if digitsPastDecimal <= 7 {
                let numberOfTrailingZerosNeeded = 7 - digitsPastDecimal

                for _ in 0...numberOfTrailingZerosNeeded {
                    btcBalanceArray.append("0")
                }
            }
            
            btcBalanceArray.insert(" ", at: decimalLocation + 3)
            btcBalanceArray.insert(" ", at: decimalLocation + 7)
            btcBalance = btcBalanceArray.joined()
        }
        
        return btcBalance
    }
}

