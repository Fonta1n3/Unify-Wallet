//
//  ReceiveAddInputOutputView.swift
//  Unify
//
//  Created by Peter Denton on 6/21/24.
//

import SwiftUI


struct ReceiveAddOutputView: View {
    @State private var errorToDisplay = ""
    @State private var showError = false
    @State private var additionalOutputAddress = ""
    @State private var additionalOutputAmount = ""
    @State private var spendableAmount = 0.0
    @State private var isShowingScanner = false
    
    
    let invoiceAmount: Double
    let invoiceAddress: String
    let utxos: [Utxo]
    
    
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
            
            Section() {
                HStack() {
                    Label("Amount", systemImage: "bitcoinsign.circle")
                        .frame(maxWidth: 200, alignment: .leading)
                    
                    Spacer()
                    
                    TextField("", text: $additionalOutputAmount)
#if os(iOS)
                        .keyboardType(.decimalPad)
#endif
                }
                
                HStack() {
                    Label("Address", systemImage: "arrow.down.forward.circle")
                        .frame(maxWidth: 200, alignment: .leading)
                    
                    Spacer()
                    
                    TextField("", text: $additionalOutputAddress)
#if os(iOS)
                        .keyboardType(.default)
                        
#endif
                        .autocorrectionDisabled()
                    
                    #if os(iOS)
                    Button {
                        isShowingScanner = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                    }
                    .sheet(isPresented: $isShowingScanner) {
                        CodeScannerView(codeTypes: [.qr], simulatedData: "", completion: handleScan)
                    }
                    #endif
                }
                
                if additionalOutputAddress != "" {
                    Text(additionalOutputAddress.withSpaces)
                } else {
                    Button {
                        guard let donationAddress = Keys.donationAddress() else { return }
                        
                        additionalOutputAddress = donationAddress
                    } label: {
                        Text("Donation address")
                    }
                }
            } header: {
                Text("Additional Output")
                
            } footer: {
                Text("Adding an output to the transaction is what makes this a Payjoin transaction. This should be a payment to another entity, a consolidation, donation etc... This output will not be shown in the invoice.")
                    .foregroundStyle(.secondary)
            }
            
            
            
            if additionalOutputAmount != "", additionalOutputAddress != "", let dblAmount = Double(additionalOutputAmount), dblAmount > 0 {
                NavigationLink(value: ReceiveNavigationLinkValues.receiveAddInputView(invoiceAmount: invoiceAmount, 
                                                                                      invoiceAddress: invoiceAddress,
                                                                                      outputAddress: additionalOutputAddress,
                                                                                      outputAmount: dblAmount,
                                                                                      utxos: utxos)) {
                    
                    Text("Select utxo's manually")
                        .foregroundStyle(.blue)
                    
                    
                }
                
                NavigationLink(value: ReceiveNavigationLinkValues.invoiceView(invoiceAmount: invoiceAmount, 
                                                                              invoiceAddress: invoiceAddress,
                                                                              additionalInputs: [],
                                                                              utxos: utxos,
                                                                              outputAddress: additionalOutputAddress,
                                                                              outputAmount: dblAmount)) {
                    
                    Text("Select utxo's automatically")
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
    
    
#if os(iOS)
    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        switch result {
        case .success(let result):
            let invoice = Invoice(result.string)
            guard let address = invoice.address,
                  let amount = invoice.amount else {
                
                self.additionalOutputAddress = result.string
                
                return
            }
            
            self.additionalOutputAddress = address
            self.additionalOutputAmount = "\(amount)"
            
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
#endif
    
    
    private func getSpendableAmount() {
        for input in utxos {
            spendableAmount += input.amount!
        }
    }
    
    
    private func showError(desc: String) {
        errorToDisplay = desc
        showError = true
    }
}
