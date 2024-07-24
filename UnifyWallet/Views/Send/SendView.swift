//
//  HomeView.swift
//  Pay Join
//
//  Created by Peter Denton on 2/13/24.
//

import SwiftUI
import PhotosUI
import NostrSDK
import SwiftUICoreImage
import LibWally

struct SendView: View, DirectMessageEncrypting {
    
    @State private var uploadedInvoice: Invoice?
    @State private var invoiceUploaded = false
    @State private var showUtxos = false
    @State private var utxos: [Utxo] = []
    @State private var showError = false
    @State private var errorDesc = ""
    @State private var fetching = true
    @State private var balance = 0.0
    
        
    var body: some View {
        Form() {
            Section("Balance") {
                HStack() {
                    Label(balance.btcBalanceWithSpaces, systemImage: "bitcoinsign.circle")
                    
                    if fetching {
                        ProgressView()
                            #if os(macOS)
                            .scaleEffect(0.5)
                            #else
                            .padding(.leading)
                            #endif
                    }
                }
            }
            
            if !invoiceUploaded {
                Section("Add Invoice") {
                    UploadInvoiceView(uploadedInvoice: $uploadedInvoice, invoiceUploaded: $invoiceUploaded)
                }
                
            } else {
                Section("Pay Invoice") {
                    if let uploadedInvoice = uploadedInvoice {
                        Label("\(uploadedInvoice.address!.withSpaces)", systemImage: "arrow.up.forward.circle")
                        
                        Label(uploadedInvoice.amount!.btcBalanceWithSpaces, systemImage: "bitcoinsign.circle")
                    }
                    
                    Button("Clear") {
                        uploadedInvoice = nil
                        invoiceUploaded = false
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            
            
            if showUtxos, let uploadedInvoice = uploadedInvoice {
                if utxos.count > 0 {
                        List() {
                            NavigationLink(value: SendNavigationLinkValues.sendUtxoView(utxos: utxos, invoice: uploadedInvoice, utxosToConsume: [])) {
                                Text("Select utxos automatically")
                            }
                            
                            NavigationLink(value: SendNavigationLinkValues.selectInputsSendView(utxos: utxos, invoice: uploadedInvoice)) {
                                Text("Select utxos manually")
                            }                            
                        }
                } else {
                    Section("UTXOs") {
                        Text("No spendable utxos.")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .multilineTextAlignment(.leading)
        .textFieldStyle(.roundedBorder)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
        .onAppear {
            uploadedInvoice = nil
            showUtxos = false
            invoiceUploaded = false
            getUtxos()
        }
        .alert(errorDesc, isPresented: $showError) {
            Button("OK", role: .cancel) {}
        }
    }
    
    
    private func displayError(desc: String) {
        errorDesc = desc
        showError = true
    }
    
    
    private func getUtxos() {
        balance = 0.0
        let p = List_Unspent([:])
        utxos.removeAll()
        
        BitcoinCoreRPC.shared.btcRPC(method: .listunspent(p)) { (response, errorDesc) in
            fetching = false
            
            guard let response = response as? [[String: Any]] else {
                displayError(desc: errorDesc ?? "Unknown error from listunspent.")
                
                return
            }
            
            guard response.count > 0 else {
                displayError(desc: "No utxos.")
                
                return
            }
            
            var spendable = false
            
            for item in response {
                let utxo = Utxo(item)
                
                if let confs = utxo.confs, confs > 0,
                   let solvable = utxo.solvable, solvable {
                    spendable = true
                    utxos.append(utxo)
                    balance += utxo.amount!
                }
            }
            
            if spendable {
                showUtxos = true
            } else {
                displayError(desc: "No spendable utxos.")
            }
        }
    }
}


struct UploadInvoiceView: View {
    @State private var isShowingScanner = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var showError = false
    @State private var errorDesc = ""
    
    @Binding var uploadedInvoice: Invoice?
    @Binding var invoiceUploaded: Bool
    
    var body: some View {
        HStack {
            PhotosPicker("Photo Library", selection: $pickerItem, matching: .images)
                .onChange(of: pickerItem) {
                    Task {
                        selectedImage = try await pickerItem?.loadTransferable(type: Image.self)
                        #if os(macOS)
                        let ciImage: CIImage = CIImage(nsImage: selectedImage!.renderAsImage()!)
                        #elseif os(iOS)
                        let ciImage: CIImage = CIImage(uiImage: selectedImage!.asUIImage())
                        #endif
                        uploadedInvoice = invoiceFromQrImage(ciImage: ciImage)
                        invoiceUploaded = true
                    }
                }
            #if os(iOS)
            // Can't scan QR on macOS with SwiftUI...
            Button {
                isShowingScanner = true
            } label: {
                Image(systemName: "qrcode.viewfinder")
            }
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(codeTypes: [.qr], simulatedData: "", completion: handleScan)
            }
            #endif
            
            Button {
                if let invoiceCheck = handlePaste() {
                    uploadedInvoice = invoiceCheck
                    invoiceUploaded = true
                } else {
                    errorDesc = "Not a valid Payjoin over Nostr invoice."
                    showError = true
                }
                
            } label: {
                Image(systemName: "doc.on.clipboard")
            }
        }
        .buttonStyle(.bordered)
        .alert(errorDesc, isPresented: $showError) {
            Button("OK", role: .cancel) {}
        }
        
        Text("Select a method to upload an invoice.")
            .foregroundStyle(.tertiary)
        
        
    }
    
#if os(iOS)
    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        switch result {
        case .success(let result):
            let invoice = Invoice(result.string)
            guard let _ = invoice.address,
                  let _ = invoice.amount,
                  let _ = invoice.recipientsNpub else {
                return
            }
            
            uploadedInvoice = invoice
            invoiceUploaded = true
            
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
#endif
    
    private func handlePaste() -> Invoice? {
#if os(macOS)
        let pasteboard = NSPasteboard.general
        
        guard let url = pasteboard.pasteboardItems?.first?.string(forType: .string) else {
            let type = NSPasteboard.PasteboardType.tiff
            guard let imgData = pasteboard.data(forType: type) else { return nil }
            let ciImage: CIImage = CIImage(nsImage: NSImage(data: imgData)!)
            return invoiceFromQrImage(ciImage: ciImage)
        }
        
        let invoice = Invoice(url)
        
        guard let _ = invoice.address, let _ = invoice.amount, let _ = invoice.recipientsNpub else {
            return nil
        }
        
        return invoice
        
#elseif os(iOS)
        let pasteboard = UIPasteboard.general
        
        guard let image = pasteboard.image else {
            guard let text = pasteboard.string else { return nil }
            let invoice = Invoice(text)
            guard let _ = invoice.address, let _ = invoice.amount else {
                return nil
            }
            
            return invoice
        }
                
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        let ciImage = CIImage(cgImage: cgImage)
                
        guard let invoice = invoiceFromQrImage(ciImage: ciImage) else {
            return nil
        }
        
        return invoice
#endif
    }
    
    private func invoiceFromQrImage(ciImage: CIImage) -> Invoice? {
        var qrCodeText = ""
        let detector: CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
        let features = detector.features(in: ciImage)
        
        for feature in features as! [CIQRCodeFeature] {
            qrCodeText += feature.messageString!
        }
        
        let invoice = Invoice(qrCodeText)
        
        guard let _ = invoice.address, let _ = invoice.amount else {
            return nil
        }
        
        return invoice
    }
}

#if os(macOS)
extension View {
    func renderAsImage() -> NSImage? {
        let view = NoInsetHostingView(rootView: self)
        view.setFrameSize(view.fittingSize)
        return view.bitmapImage()
    }
}

class NoInsetHostingView<V>: NSHostingView<V> where V: View {
    override var safeAreaInsets: NSEdgeInsets {
        return .init()
    }
}

public extension NSView {
    func bitmapImage() -> NSImage? {
        guard let rep = bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }
        
        cacheDisplay(in: bounds, to: rep)
        
        guard let cgImage = rep.cgImage else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: bounds.size)
    }
}
#endif

#if os(iOS)
extension View {
    // This function changes our View to UIView, then calls another function
    // to convert the newly-made UIView to a UIImage.
    public func asUIImage() -> UIImage {
        let controller = UIHostingController(rootView: self)
        
        // Set the background to be transparent incase the image is a PNG, WebP or (Static) GIF
        controller.view.backgroundColor = .clear
        
        controller.view.frame = CGRect(x: 0, y: CGFloat(Int.max), width: 1, height: 1)
        UIApplication.shared.windows.first!.rootViewController?.view.addSubview(controller.view)
        
        let size = controller.sizeThatFits(in: UIScreen.main.bounds.size)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.sizeToFit()
        
        // here is the call to the function that converts UIView to UIImage: `.asUIImage()`
        let image = controller.view.asUIImage()
        controller.view.removeFromSuperview()
        return image
    }
}

extension UIView {
    // This is the function to convert UIView to UIImage
    public func asUIImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
#endif
