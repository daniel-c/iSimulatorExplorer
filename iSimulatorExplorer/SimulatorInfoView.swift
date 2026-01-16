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
    var mainViewModel: SimulatorExplorerViewModel?
    var simulator: Simulator?
    var infoItems: [InfoItem] = []
    var startStopButtonText: String = "Boot"
    
    init(mainViewModel: SimulatorExplorerViewModel? = nil) {
        self.mainViewModel = mainViewModel
        if let mainViewModel = mainViewModel {
            updateSimulator(simulator: mainViewModel.getSelectedSimulator())
            withObservationTracking {
                _ = mainViewModel.selectedId
            } onChange: {
                DispatchQueue.main.async {
                    self.updateSimulator(simulator: self.mainViewModel!.getSelectedSimulator())
                }
            }
        }
    }

    func updateSimulator(simulator: Simulator?) {
        self.simulator = simulator
        infoItems.removeAll()
        
        guard let simulator = simulator else {
            return
        }
        
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
    @State private var viewModel: SimulatorInfoViewModel = SimulatorInfoViewModel(mainViewModel: nil)
    
    init(mainViewModel: SimulatorExplorerViewModel?) {
        self.viewModel = SimulatorInfoViewModel(mainViewModel: mainViewModel)
    }

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
        .padding(10)
    }
}

#Preview {
    SimulatorInfoView(mainViewModel: nil)
}
