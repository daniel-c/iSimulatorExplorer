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


struct ContentView: View {
    let simulatorManager : DCSimulatorManager = DCSimulatorManager()
    
    @State private var simulatorGroups: [SimulatorGroup] = []
    @State private var simulators: [Simulator] = []
    @State private var simulatorIds: Set<UUID> = []
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            Text("")
                .toolbar(removing: .sidebarToggle)
        } content: {
            List(simulatorGroups, id: \.id, children: \.simulators, selection: $simulatorIds, ) { simulator in
                Text(simulator.name)
            }
        } detail: {
            VStack {
                if simulatorIds.count == 1 {
                    Text(simulatorIds.first!.uuidString)
                }
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Details")
            }
            .task {
                initSimulatorList()
            }
            .padding()
        }
    }
    
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
}

#Preview {
    ContentView()
}

