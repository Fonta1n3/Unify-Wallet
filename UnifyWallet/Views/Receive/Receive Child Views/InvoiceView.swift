//
//  InvoiceView.swift
//  Unify
//
//  Created by Peter Denton on 6/22/24.
//

import Foundation
import SwiftUI
import NostrSDK
import LibWally

struct InvoiceView: View, DirectMessageEncrypting {
    @EnvironmentObject private var receiveNavigator: Navigator
    private let urlString = UserDefaults.standard.string(forKey: "nostrRelay") ?? "wss://relay.damus.io"
    @State private var invoice: Invoice?
    @State private var ourKeypair: Keypair?
    @State private var showCopiedAlert = false
    @State private var showError = false
    @State private var errorToDisplay = ""
    @State private var originalPsbt: PSBT?
    @State private var payeePubkey: PublicKey?
    @State private var peerNpub = ""
    @State private var paymentBroadcastBySender = false
    @State private var originalPsbtReceived = false
    @State private var hex: String?
    @State private var txSent = false
    @State private var showSpinner = false
    @State private var showingPassphraseAlert = false
    @State private var passphrase = ""
    @State private var passphraseConfirm = ""
    @State private var nostrConnected = false
    @State var startDate = Date.now
    @State var timeElapsed: Int = 0
    
    
    let invoiceAmount: Double
    let invoiceAddress: String
    let additionalInputs: [Utxo]?
    let utxos: [Utxo]?
    let outputAddress: String?
    let outputAmount: Double?
    
    
    var body: some View {
            Form() {
                let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                
                Toggle("Nostr status", isOn: $nostrConnected)
                    .onChange(of: nostrConnected) { oldValue, newValue in
                        if !newValue {
                            StreamManager.shared.closeWebSocket()
                        } else {
                            if StreamManager.shared.webSocket == nil {
                                connectToNostr()
                            }
                        }
                    }
                    .onReceive(timer) { firedDate in
                        timeElapsed = Int(firedDate.timeIntervalSince(startDate))
                        if timeElapsed.isMultiple(of: 10) {
                            nostrConnected = StreamManager.shared.webSocket != nil
                        }
                        
                    }
                
                if let ourKeypair = ourKeypair {
                    let url = "bitcoin:\(invoiceAddress)?amount=\(invoiceAmount)&pj=nostr:\(ourKeypair.publicKey.npub)"
                    
                    if outputAddress == nil && outputAmount == nil {
                        let standardInvoice = "bitcoin:\(invoiceAddress)?amount=\(invoiceAmount)"
                        
                        Section("Standard Invoice") {
                            Label("Standard BIP21 Invoice", systemImage: "qrcode")
                            
                            QRView(url: standardInvoice)
                            
                            HStack {
                                Text(standardInvoice)
                                    .truncationMode(.middle)
                                    .lineLimit(1)
                                
                                Button {
                                    #if os(macOS)
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(standardInvoice, forType: .string)
                                    #elseif os(iOS)
                                    UIPasteboard.general.string = standardInvoice
                                    #endif
                                    showCopiedAlert = true
                                    
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                                
                                ShareLink("Share", item: standardInvoice)
                            }
                            
                            HStack() {
                                Label {
                                    Text("Invoice Address")
                                        .foregroundStyle(.secondary)
                                } icon: {
                                    Image(systemName: "arrow.down.forward.circle")
                                        .foregroundStyle(.blue)
                                }
                                
                                Text(invoiceAddress.withSpaces)
                            }
                            
                            HStack() {
                                Label {
                                    Text("Invoice Amount")
                                        .foregroundStyle(.secondary)
                                } icon: {
                                    Image(systemName: "bitcoinsign.circle")
                                        .foregroundStyle(.blue)
                                }
                                
                                Text(invoiceAmount.btcBalanceWithSpaces)
                            }
                            
                            Text("Share this invoice with the payee.")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Section("Payjoin Invoice") {
                            Label("Payjoin over Nostr Invoice", systemImage: "qrcode")
                            
                            QRView(url: url)
                            
                            HStack {
                                Text(url)
                                    .truncationMode(.middle)
                                    .lineLimit(1)
                                
                                Button {
                                    #if os(macOS)
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(url, forType: .string)
                                    #elseif os(iOS)
                                    UIPasteboard.general.string = url
                                    #endif
                                    showCopiedAlert = true
                                    
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                                
                                ShareLink("Share", item: url)
                            }
                            
                            HStack() {
                                Label {
                                    Text("Invoice Address")
                                        .foregroundStyle(.secondary)
                                } icon: {
                                    Image(systemName: "arrow.down.forward.circle")
                                        .foregroundStyle(.blue)
                                }
                                
                                Text(invoiceAddress.withSpaces)
                            }
                            
                            HStack() {
                                Label {
                                    Text("Invoice Amount")
                                        .foregroundStyle(.secondary)
                                } icon: {
                                    Image(systemName: "bitcoinsign.circle")
                                        .foregroundStyle(.blue)
                                }
                                
                                Text(invoiceAmount.btcBalanceWithSpaces)
                            }
                            
                            Text("Share this invoice with the payee, they will send us the original psbt which we may broadcast as is or optionally create a Payjoin proposal.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                if let hex = hex {
                    Section("Signed Payment (not yet a Payjoin)") {
                        Label("Signed Transaction", systemImage: "doc.plaintext")
                        
                        HStack() {
                            Text(hex)
                                .truncationMode(.middle)
                                .lineLimit(1)
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(.primary)
                            
                            Button {
                                #if os(macOS)
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(hex, forType: .string)
                                #elseif os(iOS)
                                UIPasteboard.general.string = hex
                                #endif
                                showCopiedAlert = true
                                
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            
                            Button {
                                sendOriginalPsbt(hex: hex)
                            } label: {
                                Text("Broadcast")
                            }
                        }
                        
                        HStack() {
                            Label {
                                Text("The signed raw transaction pays your invoice address and amount.")
                            } icon: {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(.green)
                            }
                        }
                        
                        Text("Optionally broadcast the received payment from the sender instead of creating a Payjoin transaction. In order to create the Payjoin transaction you must select Create Payjoin Proposal below.")
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let _ = originalPsbt, let _ = outputAmount, let _ = outputAddress, !paymentBroadcastBySender {
                    if !showSpinner {
                        Button {
                            showingPassphraseAlert.toggle()
                        } label: {
                            Text("Create and sign Payjoin proposal")
                        }
                        .buttonStyle(.borderedProminent)
                        .alert("Enter your passphrase", isPresented: $showingPassphraseAlert) {
                            SecureField("Enter your passphrase", text: $passphrase)
                                .foregroundColor(.black)
    
                            SecureField("Confirm passphrase", text: $passphraseConfirm)
                                .foregroundColor(.black)
                            
                            HStack() {
                                Button {
                                    if passphrase == passphraseConfirm {
                                        createProposal(passphrase: passphrase)
        
                                    } else {
                                        showError(desc: "Passphrase mismatch, try again.")
                                    }
                                    showingPassphraseAlert.toggle()
                                    
                                } label: {
                                    Text("Create and sign Payjoin proposal")
                                }
                                
                                Button("Cancel", role: .cancel) {
                                    passphrase = ""
                                    passphraseConfirm = ""
                                    showingPassphraseAlert.toggle()
                                }
                            }
                        } message: {
                            Text("We will use the passphrase to create and sign the Payjoin proposal. This will be sent to the sender to verify and broadcast.")
                        }
                        .padding(.top)
                    } else {
                        HStack() {
                            ProgressView()
                            #if os(macOS)
                                .scaleEffect(0.5)
                            #endif
                            
                            Text(" Waiting on response from sender...")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                if paymentBroadcastBySender {
                    HStack() {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(.green)
                                            
                        Text("Payment received ✓")
                        
                        Button {
                            receiveNavigator.path.removeLast(receiveNavigator.path.count)
                        } label: {
                            Text("Done")
                        }
                    }
                }
            }
            .onAppear(perform: {
                hex = nil
                invoice = nil
                originalPsbt = nil
                payeePubkey = nil
                peerNpub = ""
                paymentBroadcastBySender = false
                originalPsbtReceived = false
                txSent = false
                ourKeypair = nil
                ourKeypair = Keypair()
                if StreamManager.shared.webSocket == nil {
                    connectToNostr()
                }
                
            })
            .alert(errorToDisplay, isPresented: $showError) {
                Button("OK", role: .cancel) {}
            }
            .alert("Payment was broadcast by sender ✓", isPresented: $paymentBroadcastBySender) {
                Button("OK", role: .cancel) {
                    receiveNavigator.path.removeLast(receiveNavigator.path.count)
                }
            }
            .buttonStyle(.bordered)
            .formStyle(.grouped)
            .multilineTextAlignment(.leading)
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
        
    }
    
    
    private func sendOriginalPsbt(hex: String) {
        showSpinner = true
        let p = Send_Raw_Transaction(["hexstring": hex])
        
        BitcoinCoreRPC.shared.btcRPC(method: .sendrawtransaction(p)) { (response, errorDesc) in
            guard let _ = response as? String else {
                showError(desc: errorDesc ?? "Unknown error sendrawtransaction.")
                
                return
            }
            
            self.txSent = true
            
            guard let encEvent = try? encrypt(content: "Payment broadcast by recipient ✓",
                                              privateKey: ourKeypair!.privateKey,
                                              publicKey: payeePubkey!) else {
                showError(desc: "Failed encrypting event.")
                
                return
            }
            
            StreamManager.shared.writeEvent(content: encEvent, recipientNpub: peerNpub, ourKeypair: ourKeypair!)
        }
    }
    
    
    private func showError(desc: String) {
        errorToDisplay = desc
        showSpinner = false
        showError = true
    }
    
    
    private func connectToNostr() {
        StreamManager.shared.openWebSocket(relayUrlString: urlString, peerNpub: nil, p: ourKeypair!.publicKey.hex)
        
        StreamManager.shared.eoseReceivedBlock = { _ in
                nostrConnected = true
        }
        
        StreamManager.shared.errorReceivedBlock = { nostrError in
            if nostrError != "" {
                showError(desc: nostrError)
                nostrConnected = false
                StreamManager.shared.closeWebSocket()
            }
        }
        
        StreamManager.shared.onDoneBlock = { nostrResponse in
            guard let content = nostrResponse.content else {
                guard let nostrErr = nostrResponse.errorDesc, nostrErr != "" else {
                    return
                }
                
                showError(desc: nostrErr)
                
                return
            }
            
            guard let payeePubkeyHex = nostrResponse.pubkey else {
                showError(desc: "Unable to get pubkey hex from event.")
                
                return
            }
            
            guard let payeePubkey = PublicKey(hex: payeePubkeyHex) else {
                showError(desc: "Unable to convert pubkey hex to PublicKey.")
                
                return
            }
            
            self.payeePubkey = payeePubkey
            
            peerNpub = payeePubkey.npub
            
            guard let decryptedMessage = try? decrypt(encryptedContent: content,
                                                      privateKey: ourKeypair!.privateKey,
                                                      publicKey: payeePubkey) else {
                showError(desc: "Failed decrypting message.")
                
                return
            }
                        
            if decryptedMessage == "Payment broadcast by sender ✓" {
                paymentBroadcastBySender = true
                
                return
            }
            
            guard let decryptedMessageData = decryptedMessage.data(using: .utf8) else {
                showError(desc: "Failed converting decrypted message to data.")
                
                return
            }
            
            guard let dictionary =  try? JSONSerialization.jsonObject(with: decryptedMessageData, options: [.allowFragments]) as? [String: Any] else {
                showError(desc: "Converting to dictionary failed.")
                
                return
            }
            
            let eventContent = EventContent(dictionary)
            
            guard let originalPsbtBase64 = eventContent.psbt else {
                showError(desc: "No psbt present in decrypted event dictionary.")
                
                return
            }
            
            originalPsbtReceived = true
            
            let networkSetting = UserDefaults.standard.object(forKey: "network") as? String ?? "Signet"
            var network: Network = .testnet
            
            if networkSetting == "Mainnet" {
                network = .mainnet
            }
            
            guard let psbt = try? PSBT(psbt: originalPsbtBase64, network: network) else {
                showError(desc: "Unable to convert base64 to PSBT object.")
                
                return
            }
            
            // Failing for regtest address :(
            let invoiceAddress = try! Address(string: invoiceAddress)
            var allInputsSegwit = false
            
            for input in psbt.inputs {
                if input.isSegwit {
                    allInputsSegwit = true
                }
            }
            
            var allOutputsSegwit = false
            var ourInvoiceGetsPaid = false
            
            for output in psbt.outputs {
                if output.txOutput.scriptPubKey.type == .payToWitnessPubKeyHash {
                    allOutputsSegwit = true
                }
                
                if output.txOutput.address! == invoiceAddress.description {
                    ourInvoiceGetsPaid = true
                }
            }
            
            guard allOutputsSegwit, allInputsSegwit, ourInvoiceGetsPaid else {
                showError(desc: "Either inputs/outputs are disimilar script types or our invoice isn't getting paid.")
                
                return
            }
            
            let finalizeParam = Finalize_Psbt(["psbt": psbt.description])
            
            BitcoinCoreRPC.shared.btcRPC(method: .finalizepsbt(finalizeParam)) { (response, errorDesc) in
                guard let response = response as? [String: Any],
                      let complete = response["complete"] as? Bool, complete,
                      let hex = response["hex"] as? String else {
                    
                    showError(desc: errorDesc ?? "Unknown error from finalizepsbt, perhaps its not complete?")
                    
                    return
                }
                
                let testmempoolacceptParam = Test_Mempool_Accept(["rawtxs": [hex]])
                
                BitcoinCoreRPC.shared.btcRPC(method: .testmempoolaccept(testmempoolacceptParam)) { (response, errorDesc) in
                    guard let response = response as? [[String: Any]], let allowed = response[0]["allowed"] as? Bool else {
                        showError(desc: errorDesc ?? "Unknown error from testmempoolaccept, perhaps the transaction is not allowed.")
                        
                        return
                    }
                    
                    if allowed {
                        self.hex = hex
                        self.originalPsbt = psbt
                    } else {
                        showError(desc: "Transaction not accepted by testmempoolaccept.")
                    }
                }
            }
        }
    }
    
    
    private func createProposal(passphrase: String) {
        showSpinner = true
        var inputsForParams: [[String:Any]] = []
        
        if let additionalInputs = additionalInputs {
            // add our input
            for input in additionalInputs {
                var ourInputDict: [String: Any] = [:]
                ourInputDict["txid"] = input.txid
                ourInputDict["vout"] = input.vout
                inputsForParams.append(ourInputDict)
            }
        }
        
        // add the output
        let ourOutput = [outputAddress!: "\(outputAmount!)"]
        var outputsForParams: [[String: Any]] = []
        outputsForParams.append(ourOutput)

        let options = ["add_inputs": true]

        let paramDict:[String: Any] = [
            "inputs": inputsForParams,
            "outputs": outputsForParams,
            "options": options,
            "bip32derivs": false
        ]

        let p = Wallet_Create_Funded_Psbt(paramDict)

        BitcoinCoreRPC.shared.btcRPC(method: .walletcreatefundedpsbt(param: p)) { (response, errorDesc) in
            guard let response = response as? [String: Any], let receiversPsbt = response["psbt"] as? String else {
                showError(desc: errorDesc ?? "Unknown error walletcreatefundedpsbt.")
                
                return
            }

            let param = Join_Psbt(["txs": [receiversPsbt, originalPsbt!.description]])

            BitcoinCoreRPC.shared.btcRPC(method: .joinpsbts(param)) { (response, errorMessage) in
                guard let payjoinProposalUnsigned = response as? String else {
                    showError(desc: errorMessage ?? "Uknown error joinpsbts.")
                    
                    return
                }

                Signer.sign(psbt: payjoinProposalUnsigned, passphrase: passphrase) { (signedPayjoinProposal, rawTx, errorMessage) in
                    guard let signedPayjoinProposal = signedPayjoinProposal else {
                        showError(desc: errorMessage ?? "Unknown error signing the payjoin proposal.")
                        
                        return
                    }

                    let unencryptedContent = [
                        "psbt": signedPayjoinProposal,
                        "parameters": [
//                                "version": 1,
//                                "maxAdditionalFeeContribution": 1000,
//                                "additionalFeeOutputIndex": 0,
//                                "minFeeRate": 10,
//                                "disableOutputSubstitution": true
                        ]
                    ]

                    guard let jsonData = try? JSONSerialization.data(withJSONObject: unencryptedContent, options: .prettyPrinted) else {
                        #if DEBUG
                        print("converting to jsonData failing...")
                        #endif
                        showError(desc: "Converting to jsonData failing...")
                        
                        return
                    }

                    guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                        showError(desc: "Unable to convert jsonData to jsonString.")
                        
                        return
                    }

                    guard let encPsbtProposal = encryptedMessage(ourKeypair: ourKeypair!,
                                                                 receiversNpub: peerNpub,
                                                                 message: jsonString) else {
                        
                        return
                    }

                    StreamManager.shared.writeEvent(content: encPsbtProposal, recipientNpub: peerNpub, ourKeypair: ourKeypair!)
                }
            }
        }
    }
    
    
    private func encryptedMessage(ourKeypair: Keypair, receiversNpub: String, message: String) -> String? {
        guard let receiversPubKey = PublicKey(npub: receiversNpub) else {
            showError(desc: "Unable to convert hex pubkey to PublicKey.")
            
            return nil
        }
        
        guard let encryptedMessage = try? encrypt(content: message,
                                                  privateKey: ourKeypair.privateKey,
                                                  publicKey: receiversPubKey) else {
            showError(desc: "Unable to encrypt message.")
            
            return nil
        }
        
        return encryptedMessage
    }
}


struct QRView: View {
    @State private var showCopiedAlert = false

    let url: String

    #if os(iOS)
    var body: some View {
        let image = generateQRCode(from: url)

        HStack() {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Button {
                UIPasteboard.general.image = image
                showCopiedAlert = true
            } label: {
                Image(systemName: "doc.on.doc")
            }
            
            ShareLink(item: Image(uiImage: image), preview: SharePreview("Invoice", image: Image(uiImage: image))) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            
        }
        .alert("Invoice copied ✓", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    #elseif os(macOS)

    var body: some View {
        let image = generateQRCode(from: url)

        HStack() {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.writeObjects([image])
                showCopiedAlert = true
            } label: {
                Image(systemName: "doc.on.doc")
            }
            
            ShareLink(item: Image(nsImage: image), preview: SharePreview("Invoice", image: Image(nsImage: image))) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }

        .alert("Invoice copied ✓", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    #endif

    #if os(iOS)


    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let output = outputImage.transformed(by: transform)

            if let cgImage = context.createCGImage(output, from: output.extent) {
                let uiImage = UIImage(cgImage: cgImage)

                let renderedIMage = UIGraphicsImageRenderer(size: uiImage.size, format: uiImage.imageRendererFormat).image { _ in
                    uiImage.draw(in: CGRect(origin: .zero, size: uiImage.size))
                }

                return renderedIMage
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    #elseif os(macOS)

    private func generateQRCode(from string: String) -> NSImage {
        let data = url.data(using: .ascii)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter!.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let output = filter?.outputImage?.transformed(by: transform)

        let colorParameters = [
            "inputColor0": CIColor(color: NSColor.black), // Foreground
            "inputColor1": CIColor(color: NSColor.white) // Background
        ]

        let colored = (output!.applyingFilter("CIFalseColor", parameters: colorParameters as [String : Any]))
        let rep = NSCIImageRep(ciImage: colored)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)

        return nsImage
    }
    #endif
}
