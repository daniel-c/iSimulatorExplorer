//
//  SimulatorAppView.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 15.01.2026.
//

import SwiftUI

struct SimulatorApp1 : Identifiable {
    var id : String
    var bundleName : String?
    var displayName : String?
    var path : String?
    var dataPath : String?
}

 
@Observable class SimulatorAppViewModel {
    var simulator: Simulator?
    var simulatorAppList : [SimulatorApp1] = []

    init() {
        
    }
    
    func updateSimulator(simulator: Simulator?) {
        self.simulator = simulator
        simulatorAppList.removeAll()
        guard let simulator else { return }
        let appList = simulator.getAppList()
        for app in appList
        {
            simulatorAppList.append(SimulatorApp1(id: app.identifier!,
                                                  bundleName: app.bundleName,
                                                  displayName: app.displayName,
                                                  path: app.path,
                                                  dataPath: app.dataPath))
        }
    }
}

struct AppRowView : View {
    var app: SimulatorApp1
    
    var body: some View {
        Grid {
            GridRow {
                Text(app.displayName ?? "").gridColumnAlignment(HorizontalAlignment.leading)
                Text(app.bundleName ?? "").gridColumnAlignment(HorizontalAlignment.leading)
            }
            GridRow {
                Button("Open App Bundle in finder") {
                    if let path = app.path {
                        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: path)
                    }
                }.buttonStyle(.link)
                Button("Open App Data in finder") {
                    if let path = app.dataPath {
                        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: path)
                    }
                }.buttonStyle(.link)
            }
        }
    }
}

struct SimulatorAppView: View, SimulatorController {
    @Environment(SimulatorViewModel.self) var simulatorViewModel : SimulatorViewModel
    @State private var viewModel : SimulatorAppViewModel = SimulatorAppViewModel()
    @State private var selectedAppId : String?
    @State private var disableButtons: Bool = false

    func updateSimulator(simulator: Simulator) {
        viewModel.updateSimulator(simulator: simulator)
    }

    var body: some View {
        List(viewModel.simulatorAppList, selection: $selectedAppId) {
            AppRowView(app: $0)
        }
        HStack {
            Button("Install App") {
                installApp()
            }
            .disabled(disableButtons)
            .frame(width:130)
            Spacer()
            Button("Uninstall App") {
                uninstallApp(appId: selectedAppId!)
            }
            .disabled(disableButtons || selectedAppId == nil)
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
    
    private func installApp()
    {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == NSApplication.ModalResponse.OK {
            for url in openPanel.urls {
                disableButtons = true
                //isBusy = true
                viewModel.simulator!.installApp(url, completionHandler: { (error) -> Void in
                    // isBusy = false
                    disableButtons = false
                    if error != nil {
                        AppDelegate.showModalAlert(
                            NSLocalizedString("Error installing app \(url)", comment: ""),
                            informativeText: "Error details: \(error!)")
                        print("Install app \(url) error: \(error!)", terminator:"\n")
                    }
                    else {
                        print("Install app \(url) successful", terminator:"\n")
                        viewModel.updateSimulator(simulator: viewModel.simulator!)
                    }
                })
            }
        }
    }
    
    private func uninstallApp(appId : String) {
        disableButtons = true
        viewModel.simulator!.uninstallApp(appId, completionHandler: { (error) -> Void in
            disableButtons = false
            if error != nil {

                AppDelegate.showModalAlert(
                    NSLocalizedString("Error uninstalling app \(appId)", comment: ""),
                    informativeText: "Error details: \(error!)")
            }
            else {
                print("Uninstall app \(appId) successful", terminator:"\n")
                viewModel.updateSimulator(simulator: viewModel.simulator!)
            }
        })
    }

}

#Preview {
    SimulatorAppView()
}
