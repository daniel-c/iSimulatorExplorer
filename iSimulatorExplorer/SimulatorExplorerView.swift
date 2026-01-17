//
//  ContentView.swift
//  SimulatorExplorer
//
//  Created by Daniel Cerutti on 14.01.2026.
//

import SwiftUI

class SimulatorGroup /*: Identifiable */{
    let id: UUID
    
    var name : String
    
    var simulators : [SimulatorGroup]?
    
    var simulator : Simulator?
    
    var UDID : UUID? {
        return simulator?.UDID
    }

    init(simulator : Simulator) {
        name = simulator.name!
        simulators = nil
        self.simulator = simulator
        id = simulator.UDID!
    }

    init(version : String, simulators : [Simulator]) {
        self.name = version
        self.simulators = []
        for simulator in simulators {
            let group = SimulatorGroup(simulator: simulator)
            self.simulators?.append(group)
        }
        id = UUID()
    }
}

@Observable class SimulatorExplorerViewModel {
    let simulatorManager : DCSimulatorManager = DCSimulatorManager()
    var simulatorGroups: [SimulatorGroup] = []
    var simulators: [Simulator] = []
    var selectedId : UUID? = nil

    func initSimulatorList() {
        simulators = simulatorManager.simulators
        var simulatorsByVersion = [String : [Simulator]]()
        for sim in simulators {
            let typeAndVersion : String
            switch sim.simulatorOS {
            case SimulatorOSType.tvOS:
                typeAndVersion = "tvOS Simulator \(sim.version!)"
            case SimulatorOSType.watchOS:
                typeAndVersion = "watchOS Simulator \(sim.version!)"
            default:
                typeAndVersion = "Simulator \(sim.version!)"
                
            }
            
            if simulatorsByVersion[typeAndVersion] == nil {
                let simulators = [Simulator]()
                simulatorsByVersion[typeAndVersion] = simulators
            }
            simulatorsByVersion[typeAndVersion]?.append(sim)
            
        }
        let sortedKeys = simulatorsByVersion.keys.sorted()
        //sortedKeys.sort({ (s1, s2) -> Bool in
        //    return s2 > s1
        //})
        // var simulatorVersions = [SimulatorVersion]()
        for key in sortedKeys {
            let sims = simulatorsByVersion[key]!
            simulatorGroups.append(SimulatorGroup(version: key, simulators: sims))
            
        }
    }
    
    func getSelectedSimulator(id : UUID?) -> Simulator?
    {
        if let id = id {
            return simulatorGroups.flatMap(\.simulators!).first(where: { $0.id == id })?.simulator
        }
        return nil
    }
}


struct SimulatorExplorerView: View {
    let simulatorManager : DCSimulatorManager = DCSimulatorManager()
    
    @State private var viewModel : SimulatorExplorerViewModel = SimulatorExplorerViewModel()
    @State private var simulatorId: UUID? = nil
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            Text("")
                .toolbar(removing: .sidebarToggle)
        } content: {
            List(viewModel.simulatorGroups, id: \.id, children: \.simulators, selection: $viewModel.selectedId, ) { simulator in
                Text(simulator.name)
            }
        } detail: {
            TabView {
                let simulator = viewModel.getSelectedSimulator(id: viewModel.selectedId)
                    
                Tab("Info", systemImage: "tray.and.arrow.down.fill") {
                    SimulatorInfoView(simulator: simulator)
                }
                // .badge(2)
                Tab("Apps", systemImage: "tray.and.arrow.up.fill") {
                    SimulatorAppView()
                }
                Tab("Trusted Certificates", systemImage: "person.crop.circle.fill") {
                    SimulatorTrustStoreView()
                }
                //.badge("!")
            }
            /*
            VStack {
                if let id = simulatorId {
                    Text(id.uuidString)
                }
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Details")
            }
             */
            .task {
                viewModel.initSimulatorList()
            }
            .padding()
        }
    }
}

#Preview {
    SimulatorExplorerView()
}

