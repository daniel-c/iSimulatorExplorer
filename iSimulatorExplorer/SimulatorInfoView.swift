//
//  SimulatorInfoView.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 14.01.2026.
//

import SwiftUI
internal import Combine

struct InfoItem : Identifiable {
    var id: String { name }
    let name: String
    let value: String
}

@Observable class SimulatorInfoViewModel {
    var simulator: Simulator?
    
    func updateSimulator(simulator: Simulator?) {
        self.simulator = simulator
    }
    
    func launchSimulatorApp() {
        if let simulator {
            let _ = simulator.launchSimulatorApp()
        }
    }
    
    
    func startStopSimulator() {
        if (simulator?.state == .shutDown) {
            simulator!.boot({ (error) in
                NSLog("boot complete. \(String(describing: error))")
            })
        }
        else {
            simulator?.shutdown({ (error) in
                NSLog("shudown complete. \(String(describing: error))")
            })
        }
    }
}


struct SimulatorInfoView: View {
    @State private var viewModel = SimulatorInfoViewModel()
    @Environment(SimulatorViewModel.self) var simulatorViewModel : SimulatorViewModel

    var body: some View {
        if let sim = simulatorViewModel.simulator {
            Table(of: InfoItem.self) {
                TableColumn("Name", value: \.name).width(min: 50, ideal: 80, max: 100)
                TableColumn("Value", value: \.value)
            } rows: {
                TableRow(InfoItem(name: "Name:", value: sim.name ?? ""))
                TableRow(InfoItem(name: "Version:", value: sim.version ?? ""))
                if (sim.deviceName != nil)
                {
                    TableRow(InfoItem(name: "Simulated Model:", value: sim.deviceName!))
                }
                TableRow(InfoItem(name: "UDID:", value: sim.UDID?.uuidString ?? ""))
                TableRow(InfoItem(name: "Path:", value: (sim.path as NSString?)?.abbreviatingWithTildeInPath ?? ""))
                TableRow(InfoItem(name: "State:", value: sim.stateString))
            }
        }
        Spacer()
        HStack {
            Button("Show in Finder") {
                if let simulator = viewModel.simulator {
                    NSWorkspace.shared.selectFile(simulator.path, inFileViewerRootedAtPath: simulator.path)
                }
            }
            .frame(width:130)
            Spacer()
            Button("Open Simulator") {
                viewModel.launchSimulatorApp()
            }
            .frame(width:130)
            Spacer()
            //Button(viewModel.startStopButtonText) {
            Button(simulatorViewModel.simulator?.state  == .shutDown ? "Boot" : "Shutdown") {
                viewModel.startStopSimulator()
            }
            .frame(width:130)
        }
        .padding(10)
        .onAppear {
            viewModel.updateSimulator(simulator: simulatorViewModel.simulator)
        }
        .onChange(of: simulatorViewModel.simulator) { _, newValue in
            viewModel.updateSimulator(simulator: newValue)
        }
    }
}

#Preview {
    SimulatorInfoView()
}
