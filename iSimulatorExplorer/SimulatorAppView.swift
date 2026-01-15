//
//  SimulatorAppView.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 15.01.2026.
//

import SwiftUI

struct SimulatorApp1 : Identifiable {
    var id : String = UUID().uuidString
    var bundleName : String
    var displayName : String
    var path : String
    var dataPath : String
}

struct AppRowView : View {
    var app: SimulatorApp1
    
    var body: some View {
        Grid {
            GridRow {
                Text(app.displayName)
                Image(systemName: "globe")
            }
            GridRow {
                Image(systemName: "globe")
                Text(app.bundleName)
            }
        }
    }
}

struct SimulatorAppView: View {
    struct Ocean: Identifiable {
        let name: String
        let id = UUID()
    }
    
    var simulatorAppList = [
        SimulatorApp1(bundleName: "ch.ceruttisoftware.test1",
                      displayName: "SimulatorApp1",
                      path: "/Users/daniel/Development/CSD/iSimulatorExplorer",
                      dataPath: "/Users/daniel/Development/CSD/iSimulatorExplorer"),
        SimulatorApp1(bundleName: "ch.ceruttisoftware.test2",
                      displayName: "SimulatorApp2",
                      path: "/Users/daniel/Development/CSD/iSimulatorExplorer",
                      dataPath: "/Users/daniel/Development/CSD/iSimulatorExplorer")
    ]
    
    private var oceans = [
        Ocean(name: "Pacific"),
        Ocean(name: "Atlantic"),
        Ocean(name: "Indian"),
        Ocean(name: "Southern"),
        Ocean(name: "Arctic")
    ]

    
    var body: some View {
        List(simulatorAppList) {
            AppRowView(app: $0)
            //Text($0.displayName)
        }
    }
}

#Preview {
    SimulatorAppView()
}
