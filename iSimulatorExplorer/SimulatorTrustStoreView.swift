//
//  SimulatorTrustStoreView.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 15.01.2026.
//

import SwiftUI

struct TrustStoreItem: Identifiable {
    var id : String
    
    var item : DCSimulatorTruststoreItem
}


@Observable class SimulatorTrustStoreViewModel {
    var truststore : DCSimulatorTruststore?
    var items : [TrustStoreItem] = []

    func updateSimulator(simulator: Simulator?)
    {
        truststore = nil
        items.removeAll()
        if let truststorePath = simulator?.trustStorePath {
            if FileManager.default.fileExists(atPath: truststorePath) {
                truststore = DCSimulatorTruststore(path : truststorePath)
                truststore!.openTrustStore()
                NSLog("Trustore has \(truststore!.items.count) items")
                for item in truststore!.items {
                    items.append(TrustStoreItem(id: UUID().uuidString, item: item))
                }
            }
        }
        // If we do not find the truststore.sqlite3 file it is usually because the simulator has not yet been run
        // the trustore property is nil in this case
    }
    
    func importCertificateFromServer(certificate: SecCertificate) {
        let item = DCSimulatorTruststoreItem(certificate: certificate)
        if let truststore = truststore, truststore.addItem(item) {
            items.append(TrustStoreItem(id: UUID().uuidString, item: item))
        }
    }
    
    func importCertificateFromFile() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == NSApplication.ModalResponse.OK {
            for url in openPanel.urls {
                if let data = try? Data(contentsOf: url) {
                    
                    var format : SecExternalFormat = SecExternalFormat.formatUnknown
                    var itemType : SecExternalItemType = SecExternalItemType.itemTypeCertificate
                    //var outItems : Unmanaged<CFArray>?
                    var outItems : CFArray?
                    //var outItems : UnsafeMutablePointer<CFArray?>
                    
                    SecItemImport(data as CFData, nil, &format, &itemType, SecItemImportExportFlags(rawValue: 0), nil, nil, &outItems)
                    //if let itemCFArray = outItems?.takeRetainedValue() {
                    if let itemCFArray = outItems {
                        let itemArray = itemCFArray as NSArray
                        if itemArray.count > 0 && itemType == SecExternalItemType.itemTypeCertificate {
                            
                            // Here we must use an unconditional downcast (conditional downcast does not work here).
                            let item = DCSimulatorTruststoreItem(certificate: itemArray[0] as! SecCertificate)
                            
                            if truststore!.addItem(item) {
                                items.append(TrustStoreItem(id: UUID().uuidString, item: item))
                            }
                        }
                    }
                }
            }
        }
    }
    
    func removeCertificate(id : String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }
        if truststore != nil {
            if truststore!.removeItem(index) {
                items.remove(at: index)
            }
        }
    }
    
    func exportCertificate(id : String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }
        if truststore != nil {
            let item = truststore!.items[index]
            let savePanel = NSSavePanel()
            if let text = item.subjectSummary {
                savePanel.nameFieldStringValue = text
            }
            if savePanel.runModal() == NSApplication.ModalResponse.OK {
                if let url = savePanel.url {
                    _ = item.export(url)
                }
            }
        }
    }
}

struct TrustStoreRowView : View {
    var item: TrustStoreItem
    
    var body: some View {
        HStack {
            Text(item.item.subjectSummary ?? "").frame(maxWidth: .infinity, alignment: .leading)
            Button() {
                if let cert = item.item.certificate {
                    SFCertificatePanel.shared().runModal(forCertificates: [cert], showGroup: false)
                }

            } label: {
                Image("ViewDetail")
            }.frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}


struct SimulatorTrustStoreView: View, SimulatorController {
    
    @State private var viewModel : SimulatorTrustStoreViewModel = SimulatorTrustStoreViewModel()
    @State private var selectedCertificateId : String?
    @State private var isDialogShown = false

    func updateSimulator(simulator: Simulator) {
        viewModel.updateSimulator(simulator: simulator)
    }
    
    var body: some View {
        if (viewModel.truststore != nil) {
            List(viewModel.items, selection: $selectedCertificateId) {
                TrustStoreRowView(item: $0)
            }
            HStack {
                Button("Import from server") {
                    isDialogShown = true
                    //viewModel.importCertificateFromServer()
                }.sheet(isPresented: $isDialogShown) {
                    ImportCertificateView(trustStoreViewModel: viewModel)
                        .frame(width:700, height:500)
                        //.presentationSizing(.form)
                }
                .frame(width:130)
                Spacer()
                Button("Import file") {
                    viewModel.importCertificateFromFile()
                }
                .frame(width:130)
                Spacer()
                Button("Remove") {
                    if let id = selectedCertificateId {
                        viewModel.removeCertificate(id: id)
                    }
                }
                .frame(width:130)
                .disabled(selectedCertificateId == nil)
                Spacer()
                if #available(macOS 26.0, *) {
                    Button("Export") {
                        if let id = selectedCertificateId {
                            viewModel.exportCertificate(id: id)
                        }
                    }
                    .buttonSizing(.flexible)
                    .frame(width: 130)
                    .disabled(selectedCertificateId == nil)
                } else {
                    Button("Export") {
                        if let id = selectedCertificateId {
                            viewModel.exportCertificate(id: id)
                        }
                    }
                    .frame(width: 130)
                    .disabled(selectedCertificateId == nil)

                }
            }.padding(10)
        }
        else {
            Text("The trusted certificate list is not available until the simulator for the selected device has been started once.").foregroundStyle(.red)
        }
    }
}

#Preview {
    SimulatorTrustStoreView()
}
