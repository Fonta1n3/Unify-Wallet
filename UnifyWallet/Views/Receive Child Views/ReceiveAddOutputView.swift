//
//  ReceiveAddInputOutputView.swift
//  Unify
//
//  Created by Peter Denton on 6/21/24.
//

import SwiftUI
import LibWally


struct ReceiveAddOutputView: View {
    @State private var errorToDisplay = ""
    @State private var showError = false
    @State private var additionalOutputAddress = ""
    @State private var additionalOutputAmount = ""
    @State private var spendableAmount = 0.0
    
    
    let invoiceAmount: Double
    let invoiceAddress: String
    let additionalInputs: [Utxo]
    let utxos: [Utxo]
    
    
    init(invoiceAmount: Double, invoiceAddress: String, additionalInputs: [Utxo], utxos: [Utxo]) {
        self.invoiceAmount = invoiceAmount
        self.invoiceAddress = invoiceAddress
        self.additionalInputs = additionalInputs
        self.utxos = utxos
    }
    
    
    var body: some View {
        Form() {
            Section("Spendable Amount") {
                Label {
                    Text(spendableAmount.btcBalanceWithSpaces)
                        .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            Section("Additional Output") {
                HStack() {
                    Label("BTC Amount", systemImage: "bitcoinsign.circle")
                        .frame(maxWidth: 200, alignment: .leading)
                    
                    Spacer()
                    
                    TextField("", text: $additionalOutputAmount)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                
                HStack() {
                    Label("Recipient address", systemImage: "arrow.down.forward.circle")
                        .frame(maxWidth: 200, alignment: .leading)
                    
                    Spacer()
                    
                    TextField("", text: $additionalOutputAddress)
                        #if os(iOS)
                        .keyboardType(.default)
                        #endif
                }
            }
            
            Text("Adding an output to the transaction is what makes this a Pajoin transaction. This should be a payment to another entity or a consolidation. This output will not be shown in the invoice.")
                .foregroundStyle(.secondary)
            
            if additionalOutputAmount != "", additionalOutputAddress != "" {
                NavigationLink {
                    InvoiceView(invoiceAmount: invoiceAmount,
                                invoiceAddress: invoiceAddress,
                                additionalInputs: additionalInputs, 
                                utxos: utxos,
                                outputAddress: additionalOutputAddress,
                                outputAmount: additionalOutputAmount)
                } label: {
                    Text("View Invoice")
                        .foregroundStyle(.blue)
                }
            }
        }
        .onAppear() {
            getSpendableAmount()
        }
        .alert(errorToDisplay, isPresented: $showError) {
            Button("OK", role: .cancel) {}
        }
        .buttonStyle(.bordered)
        .formStyle(.grouped)
        .multilineTextAlignment(.leading)
        .textFieldStyle(.roundedBorder)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
    }
    
    
    private func getSpendableAmount() {
        if additionalInputs.count > 0 {
            for input in additionalInputs {
                spendableAmount += input.amount!
            }
        } else {
            for input in utxos {
                spendableAmount += input.amount!
            }
        }
    }
    
    
    private func showError(desc: String) {
        errorToDisplay = desc
        showError = true
    }
}
