//
//  SimulatorInfoView.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 14.01.2026.
//

import SwiftUI

struct InfoItem : Identifiable {
    var id: String { name }
    let name: String
    let value: String
}


struct SimulatorInfoView: View, SimulatorController {
    var _simulator : Simulator?
    var simulator: Simulator? {
        get { return _simulator }
        set {
            _simulator = newValue
            infoItems.removeAll()
            
            let empty = ""
            infoItems.append(InfoItem(name: NSLocalizedString("Name:", comment: ""), value: simulator!.name ?? empty))
            if simulator!.deviceName != nil {
                infoItems.append(InfoItem(name: NSLocalizedString("Simulated Model:", comment: ""), value: simulator!.deviceName!))
            }
            infoItems.append(InfoItem(name: NSLocalizedString("Version:", comment: ""), value: (simulator!.version ?? empty)))
            if simulator!.UDID != nil {
                infoItems.append(InfoItem(name: NSLocalizedString("UDID:", comment: ""), value: simulator!.UDID!.uuidString))
            }
            infoItems.append(InfoItem(name: NSLocalizedString("Path:", comment: ""), value: (simulator!.path as NSString?)?.abbreviatingWithTildeInPath ?? empty))
            infoItems.append(InfoItem(name: NSLocalizedString("State:", comment: ""), value: simulator!.stateString))

        }
    }
    
    var infoItems: [InfoItem] = []
    
    var body: some View {
        Table(infoItems) {
            TableColumn("Name", value: \.name)
            TableColumn("Value", value: \.value)
        }
        HStack {
            Button("Show in Finder") {
                
            }
            Spacer()
            Button("Open Simulator") {
                
            }
            Spacer()
            Button("Boot") {
                
            }
        }
    }
}

#Preview {
    SimulatorInfoView()
}
