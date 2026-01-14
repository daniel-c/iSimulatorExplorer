//
//  SimulatorExplorerMainView.swift
//  SimulatorExplorer
//
//  Created by Daniel Cerutti on 14.01.2026.
//

import SwiftUI

struct SimulatorExplorerMainView: NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> DCSimulatorExplorerController {
        let vc = DCSimulatorExplorerController()
        return vc
    }
    
    func updateNSViewController(_ nsViewController: DCSimulatorExplorerController, context: Context) {
        
    }
    
    typealias NSViewControllerType = DCSimulatorExplorerController
    
}

#Preview {
    SimulatorExplorerMainView()
}
