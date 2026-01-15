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

@Observable class SimulatorInfoViewModel {
    var simulator: Simulator?
    var infoItems: [InfoItem] = []
    var startStopButtonText: String = "Boot"

    func updateSimulator(simulator: Simulator) {
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

        startStopButtonText = simulator.state == .shutDown ? "Boot" : "Shutdown"
    }
}


struct SimulatorInfoView: View, SimulatorController {
    @State private var viewModel: SimulatorInfoViewModel = SimulatorInfoViewModel()

    func updateSimulator(simulator: Simulator) {
        viewModel.updateSimulator(simulator: simulator)
    }
    
    var body: some View {
        Table(viewModel.infoItems) {
            TableColumn("Name", value: \.name).width(min: 50, ideal: 80, max: 100)
            TableColumn("Value", value: \.value)
        }
        HStack {
            Button("Show in Finder") {
                if let simulator = viewModel.simulator {
                    NSWorkspace.shared.selectFile(simulator.path, inFileViewerRootedAtPath: simulator.path)
                }
            }
            .frame(width:130)
            Spacer()
            Button("Open Simulator") {
                if let simulator = viewModel.simulator {
                    let _ = simulator.launchSimulatorApp()
                }
            }
            .frame(width:130)
            Spacer()
            Button(viewModel.startStopButtonText) {
                if (viewModel.simulator?.state == .shutDown) {
                    viewModel.simulator!.boot({ (error) in
                        NSLog("boot complete. \(String(describing: error))")
                    })
                }
                else {
                    viewModel.simulator?.shutdown({ (error) in
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
