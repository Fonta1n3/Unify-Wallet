//
//  SendNavigationLinkValues.swift
//  UnifyWallet
//
//  Created by Peter Denton on 6/24/24.
//

import SwiftUI


enum SendNavigationLinkValues: Hashable, View {
    
    case selectInputsSendView(utxos: [Utxo],
                              invoice: Invoice)
    
    case sendUtxoView(utxos: [Utxo],
                      invoice: Invoice,
                      utxosToConsume: [Utxo])
    
    case signedProposalView(signedRawTx: String, 
                            invoice: Invoice,
                            ourNostrPrivKey: String,
                            recipientsPubkey: String,
                            psbtProposalString: String)
    
    case broadcastView(hexstring: String,
                       invoice: Invoice,
                       ourNostrPrivateKey: String,
                       recipientsPubkey: String)
    
    
    
    var body: some View {
        switch self {
        case .selectInputsSendView(let utxos, let invoice):
            
            SelectInputsSendView(utxos: utxos, 
                                 invoice: invoice)
            
        case .sendUtxoView(let utxos, let invoice, let utxosToConsume):
            
            SendUtxoView(utxos: utxos,
                         invoice: invoice,
                         utxosToConsume: utxosToConsume)
            
        case .signedProposalView(let signedRawTx, let invoice, let ourNostrPrivKey, let recipientsPubkey, let psbtProposalString):
            
            SignedProposalView(signedRawTx: signedRawTx,
                               invoice: invoice,
                               ourNostrPrivKey: ourNostrPrivKey,
                               recipientsPubkey: recipientsPubkey,
                               psbtProposalString: psbtProposalString)
            
            
        case .broadcastView(let hexstring, let invoice, let ourNostrPrivateKey, let recipientsPubkey):
            
            BroadcastView(hexstring: hexstring,
                          invoice: invoice,
                          ourNostrPrivateKey: ourNostrPrivateKey,
                          recipientsPubkey: recipientsPubkey)
        }
            
    }
}
