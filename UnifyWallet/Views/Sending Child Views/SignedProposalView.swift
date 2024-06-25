//
//  SignedProposalView.swift
//  Unify
//
//  Created by Peter Denton on 6/18/24.
//

import Foundation
import SwiftUI
import LibWally
import NostrSDK

struct SignedProposalView: View, DirectMessageEncrypting {
    @State private var copied = false
    @State private var proposalPsbtReceived = false
    @State private var txid: String?
    @State private var errorToDisplay = ""
    @State private var showError = false
    @State private var ourKeypair: Keypair? = nil
    @State private var recipientsPublicKey: PublicKey? = nil
    @State private var psbtProposal: PSBT? = nil

    
    let signedRawTx: String
    let invoice: Invoice
    let ourNostrPrivKey: String
    let recipientsPubkey: String
    let psbtProposalString: String

    
    var body: some View {
        if let psbtProposal = psbtProposal {
            Form() {
                Section("Signed Tx") {
                    Label("Raw transaction", systemImage: "doc.plaintext")
                    
                    HStack() {
                        Text(signedRawTx)
                            .truncationMode(.middle)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.secondary)
                        
                        Button {
#if os(macOS)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(signedRawTx, forType: .string)
#elseif os(iOS)
                            UIPasteboard.general.string = signedRawTx
#endif
                            copied = true
                            
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                    
                    Label("PSBT", systemImage: "doc.plaintext.fill")
                    
                    HStack() {
                        Text(psbtProposalString)
                            .truncationMode(.middle)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.secondary)
                        
                        Button {
#if os(macOS)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(psbtProposalString, forType: .string)
#elseif os(iOS)
                            UIPasteboard.general.string = psbtProposalString.description
#endif
                            copied = true
                            
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                    ForEach(Array(psbtProposal.inputs.enumerated()), id: \.offset) { (index, input) in
                        let inputAmount = (Double(input.amount!) / 100000000.0).btcBalanceWithSpaces
                        
                        HStack() {
                            Label("Input", systemImage: "arrow.down.right.circle")
                            Spacer()
                            Text(inputAmount)
                        }
                    }
                    
                    ForEach(Array(psbtProposal.outputs.enumerated()), id: \.offset) { (index, output) in
                        let btcAmount = (Double(output.txOutput.amount) / 100000000.0)
                        let outputAmount = btcAmount.btcBalanceWithSpaces
                        
                        if let outputAddress = output.txOutput.address {
                            let bold = outputAddress == invoice.address && btcAmount == invoice.amount!
                            
                            HStack() {
                                Label("Output", systemImage: "arrow.up.right.circle")
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    if bold {
                                        Text(outputAddress)
                                            .bold(bold)
                                            .foregroundStyle(.primary)
                                        
                                        Text(outputAmount)
                                            .bold(bold)
                                            .foregroundStyle(.primary)
                                        
                                    } else {
                                        Text(outputAddress)
                                            .bold(bold)
                                            .foregroundStyle(.secondary)
                                        
                                        Text(outputAmount)
                                            .bold(bold)
                                            .foregroundStyle(.secondary)
                                        
                                    }
                                }
                            }
                        }
                    }
                    
                    HStack() {
                        Label("Fee", systemImage: "bitcoinsign")
                        
                        Spacer()
                        
                        Text((Double(psbtProposal.fee!) / 100000000.0).btcBalanceWithSpaces)
                    }
                    
                    NavigationLink(value: SendNavigationLinkValues.broadcastView(hexstring: signedRawTx, invoice: invoice, ourNostrPrivateKey: ourNostrPrivKey, recipientsPubkey: recipientsPubkey)) {
                        Text("Broadcast payment")
                    }
                }
                .buttonStyle(.bordered)
                .alert("Copied ✓", isPresented: $copied) {}
                .alert("Payjoin Proposal PSBT received ✓", isPresented: $proposalPsbtReceived) {
                    Button("OK", role: .cancel) {}
                }
            }
            .formStyle(.grouped)
            .multilineTextAlignment(.leading)
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
        } else {
            Text("loading...")
                .onAppear {
                    guard let ourNostrPrivKey = PrivateKey(hex: ourNostrPrivKey) else { return }
                    
                    ourKeypair = Keypair(privateKey: ourNostrPrivKey)!
                    recipientsPublicKey = PublicKey(hex: recipientsPubkey)!
                    psbtProposal = try! PSBT(psbt: psbtProposalString, network: .testnet)
                }
        }
    }
    
    
    private func displayError(desc: String) {
        errorToDisplay = desc
        showError = true
    }
}
