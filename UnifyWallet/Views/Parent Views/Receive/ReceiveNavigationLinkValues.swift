//
//  ReceiveNavigationLinkValues.swift
//  UnifyWallet
//
//  Created by Peter Denton on 6/25/24.
//

import SwiftUI

enum ReceiveNavigationLinkValues: Hashable, View {
    
    case receiveAddOutputView(invoiceAmount: Double, 
                              invoiceAddress: String,
                              utxos: [Utxo])
    
    case invoiceView(invoiceAmount: Double, 
                     invoiceAddress: String,
                     additionalInputs: [Utxo]?,
                     utxos: [Utxo]?,
                     outputAddress: String?,
                     outputAmount: Double?)
    
    case receiveAddInputView(invoiceAmount: Double, 
                             invoiceAddress: String,
                             outputAddress: String,
                             outputAmount: Double,
                             utxos: [Utxo])
    
    var body: some View {
        switch self {
        case .receiveAddOutputView(let invoiceAmount, let invoiceAddress, let utxos):
            
            ReceiveAddOutputView(invoiceAmount: invoiceAmount, 
                                 invoiceAddress: invoiceAddress,
                                 utxos: utxos)
            
        case .invoiceView(let invoiceAmount, let invoiceAddress, let additionalInputs, let utxos, let outputAddress, let outputAmount):
            
            InvoiceView(invoiceAmount: invoiceAmount, 
                        invoiceAddress: invoiceAddress,
                        additionalInputs: additionalInputs,
                        utxos: utxos,
                        outputAddress: outputAddress,
                        outputAmount: outputAmount)
            
        case .receiveAddInputView(let invoiceAmount, let invoiceAddress, let outputAddress, let outputAmount, let utxos):
            
            ReceiveAddInputView(invoiceAmount: invoiceAmount, 
                                invoiceAddress: invoiceAddress,
                                outputAddress: outputAddress,
                                outputAmount: outputAmount,
                                utxos: utxos)
        }
    }
}


