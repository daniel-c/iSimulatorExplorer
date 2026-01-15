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
    var hasItems : Bool = false
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
        //tableView.reloadData()
        //enableButtons()
        if simulator != nil && truststore == nil {
            // If we do not find the truststore.sqlite3 file it is usually because the simulator has not yet been run
            // indicate it with an appropriate message and hide the tableview
            hasItems = false
            //notavailableInfoTextField.isHidden = false
            //tableScrollView!.isHidden = true
        }
        else {
            hasItems = true
            //notavailableInfoTextField.isHidden = true
            //tableScrollView!.isHidden = false
        }
    }
}



struct SimulatorTrustStoreView: View, SimulatorController {
    
    @State private var viewModel : SimulatorTrustStoreViewModel = SimulatorTrustStoreViewModel()
    @State private var selectedCertificateId : String?

    func updateSimulator(simulator: Simulator) {
        viewModel.updateSimulator(simulator: simulator)
    }
    
    var body: some View {
        List(viewModel.items, selection: $selectedCertificateId) {
            Text($0.item.subjectSummary ?? "")
            Image("ViewDetail")
        }
        HStack {
            Button("Import from server") {
            }
            .disabled(!viewModel.hasItems)
            .frame(width:130)
            Spacer()
            Button("Import file") {
            }
            .disabled(!viewModel.hasItems)
            .frame(width:130)
            Spacer()
            Button("Remove") {
            }
            .disabled(!viewModel.hasItems || selectedCertificateId == nil)
            .frame(width:130)
            Spacer()
            Button("Export") {
            }
            .disabled(!viewModel.hasItems || selectedCertificateId == nil)
            .frame(width:130)
        }
    }
}

#Preview {
    SimulatorTrustStoreView()
}
