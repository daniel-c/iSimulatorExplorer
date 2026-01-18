//
//  ContentView.swift
//  SimulatorExplorer
//
//  Created by Daniel Cerutti on 14.01.2026.
//

import SwiftUI


struct SimulatorItem : Identifiable, Hashable {
    let id: UUID

    let name: String
}

struct SimulatorGroup: Identifiable {
    let id = UUID()
    
    let name: String
    
    var simulators: [SimulatorItem]
    
    init(version : String, simulators : [Simulator]) {
        self.name = version
        self.simulators = []
        for simulator in simulators {
            let group = SimulatorItem(id: simulator.UDID!, name: simulator.name ?? "")
            self.simulators.append(group)
        }
    }
}

@Observable class SimulatorViewModel {
    let simulatorManager : DCSimulatorManager = DCSimulatorManager()
    var simulatorGroups : [SimulatorGroup] = []
    var simulators: [Simulator] = []
    var selectedId : UUID? = nil
    var simulator: Simulator? = nil

    func initSimulatorList() {
        simulators = simulatorManager.simulators
        simulatorGroups.removeAll()
        var simulatorsByVersion = [String : [Simulator]]()
        for sim in simulators {
            let typeAndVersion : String
            switch sim.simulatorOS {
            case SimulatorOSType.tvOS:
                typeAndVersion = "tvOS Simulator \(sim.version!)"
            case SimulatorOSType.watchOS:
                typeAndVersion = "watchOS Simulator \(sim.version!)"
            default:
                typeAndVersion = "iOS Simulator \(sim.version!)"
                
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

        //guard let simulator else { return }

        switch notificationType {
        case .deviceState:
            break
        case .deviceAdded, .deviceRemoved, .deviceRenamed:
            initSimulatorList()
            break
        }

    }

    
    func setSelectedSimulator()
    {
        if let id = selectedId {
            simulator =  simulators.first(where: { $0.UDID == id })
            return
        }
        simulator = nil
    }
}

struct SimulatorExplorerView: View {
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    @State private var simulatorViewModel = SimulatorViewModel()

    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            Text("")
                .toolbar(removing: .sidebarToggle)
        } content: {
            List(selection: $simulatorViewModel.selectedId) {
                ForEach(simulatorViewModel.simulatorGroups) { group in
                    Section(header: Text(group.name)) {
                        ForEach(group.simulators) { simulatorItem in
                            HStack {
                                Image("Simulator")
                                Text(simulatorItem.name)
                            }
                        }
                    }
                }
            } .onChange(of: simulatorViewModel.selectedId) {
                simulatorViewModel.setSelectedSimulator()
            }

        } detail: {
            TabView {
                Tab("Info", systemImage: "info.circle") {
                    SimulatorInfoView()
                }
                // .badge(2)
                Tab("Apps", systemImage: "apps.iphone") {
                    SimulatorAppView()
                }
                Tab("Trusted Certificates", systemImage: "key.2.on.ring") {
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

