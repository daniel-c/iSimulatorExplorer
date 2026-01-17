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

@Observable class SimulatorViewModel {
    let simulatorManager : DCSimulatorManager = DCSimulatorManager()
    var simulatorGroups: [SimulatorGroup] = []
    var simulators: [Simulator] = []
    var selectedId : UUID? = nil
    var simulator: Simulator? = nil

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
        simulatorManager.startNotificationHandler(simDeviceChanged)
    }
    
    func simDeviceChanged (_ notificationType :  DCSimulatorManager.NotificationType, deviceUDID : UUID, newState : Int) -> Void {
        
        guard let simulator else { return }
/*
        switch notificationType {
        case .deviceState, .deviceRenamed:
            if simulator.UDID == deviceUDID {
                self.state = self.simulator?.state
            }
        case .deviceAdded, .deviceRemoved:
           break
        }
*/
    }

    
    func setSelectedSimulator()
    {
        if let id = selectedId {
            simulator =  simulatorGroups.flatMap(\.simulators!).first(where: { $0.id == id })?.simulator
            //state = simulator?.state
            return
        }
        simulator = nil
    }
}

struct SimulatorExplorerView: View {
    let simulatorManager : DCSimulatorManager = DCSimulatorManager()
    
    // @State private var simulatorId: UUID? = nil
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    @State private var simulatorViewModel = SimulatorViewModel()

    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            Text("")
                .toolbar(removing: .sidebarToggle)
        } content: {
            List(simulatorViewModel.simulatorGroups, id: \.id, children: \.simulators, selection: $simulatorViewModel.selectedId, ) { simulator in
                Text(simulator.name)
            }.onChange(of: simulatorViewModel.selectedId) {
                simulatorViewModel.setSelectedSimulator()
            }
        } detail: {
            TabView {
                Tab("Info", systemImage: "tray.and.arrow.down.fill") {
                    SimulatorInfoView()
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
            .environment(simulatorViewModel)
            .task {
                simulatorViewModel.initSimulatorList()
            }
            .padding()
        }
    }
}

#Preview {
    SimulatorExplorerView()
}

