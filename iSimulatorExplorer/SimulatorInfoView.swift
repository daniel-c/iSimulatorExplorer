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
    private var simulator: Simulator?
    private var infoItems: [InfoItem] = []
    private var startStopButtonText: String = "Boot"

    mutating func updateSimulator(simulator: Simulator) {
        self.simulator = simulator
        infoItems.removeAll()
        
        let empty = ""
        infoItems.append(InfoItem(name: NSLocalizedString("Name:", comment: ""), value: simulator.name ?? empty))
        if simulator.deviceName != nil {
            infoItems.append(InfoItem(name: NSLocalizedString("Simulated Model:", comment: ""), value: simulator.deviceName!))
        }
        infoItems.append(InfoItem(name: NSLocalizedString("Version:", comment: ""), value: (simulator.version ?? empty)))
        if simulator.UDID != nil {
            infoItems.append(InfoItem(name: NSLocalizedString("UDID:", comment: ""), value: simulator.UDID!.uuidString))
        }
        infoItems.append(InfoItem(name: NSLocalizedString("Path:", comment: ""), value: (simulator.path as NSString?)?.abbreviatingWithTildeInPath ?? empty))
        infoItems.append(InfoItem(name: NSLocalizedString("State:", comment: ""), value: simulator.stateString))

        // self.infoItems = infoItems
        
        startStopButtonText = simulator.state == .shutDown ? "Boot" : "Shutdown"
    }
    
    
    
    var body: some View {
        Table(infoItems) {
            TableColumn("Name", value: \.name).width(min: 50, ideal: 80, max: 100)
            TableColumn("Value", value: \.value)
        }
        HStack {
            Button("Show in Finder") {
                if simulator != nil {
                    NSWorkspace.shared.selectFile(simulator!.path, inFileViewerRootedAtPath: simulator!.path)
                }
            }
            .frame(width:130)
            Spacer()
            Button("Open Simulator") {
                if simulator != nil {
                    let _ = simulator?.launchSimulatorApp()
                }
            }
            .frame(width:130)
            Spacer()
            Button(startStopButtonText) {
                if (simulator!.state == .shutDown) {
                    simulator?.boot({ (error) in
                        NSLog("boot complete. \(String(describing: error))")
                    })
                }
                else {
                    simulator?.shutdown({ (error) in
                        NSLog("shudown complete. \(String(describing: error))")
                    })
                }
            }
            .frame(width:130)
        }
    }
}

#Preview {
    SimulatorInfoView()
}
