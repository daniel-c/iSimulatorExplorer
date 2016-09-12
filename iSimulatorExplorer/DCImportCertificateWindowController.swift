//
//  DCImportCertificateWindowController.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 11.10.14.
//  Copyright (c) 2014 Daniel Cerutti. All rights reserved.
//  Licensed under the MIT license. See LICENSE file in the project root for full license information.
//

import Cocoa

class DCImportCertificateWindowController: NSWindowController, NSWindowDelegate, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate {

    @IBOutlet weak var urlTextField: NSTextField!
    @IBOutlet weak var infoTextField: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var importButton: NSButton!
    @IBOutlet weak var getServerDataButton: NSButton!
    
    private var certificates : [SecCertificate]?
    
    var certificate : SecCertificate?
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        
        self.window!.delegate = self
        enableButtons()
        enableGetServerDataButton()
    }
    
    func enableButtons() {
        importButton.isEnabled = (tableView.selectedRow >= 0)
    }
    
    func enableGetServerDataButton() {
        getServerDataButton.isEnabled = (urlTextField.stringValue != "")
    }
    
    
    @IBAction func cancelButtonPressed(_ sender: AnyObject) {
        NSApplication.shared().stopModal(withCode: 1)
        window!.close();
    }
    
    func windowShouldClose(_ sender: Any) -> Bool {
        NSApplication.shared().stopModal(withCode: 2)
        return true
    }

    @IBAction func importButtonPressed(_ sender: AnyObject) {
        if tableView.selectedRow >= 0 {
            certificate = certificates?[tableView.selectedRow]
        }
        NSApplication.shared().stopModal(withCode: 0)
        window!.close();
    }

    @IBAction func getServerDataButtonPressed(_ sender: AnyObject) {
        if let url = URL(string: "https://" + urlTextField.stringValue) {
            print("url scheme: \(url.scheme) absolute: \(url.absoluteString)", terminator: "\n")
            let request = URLRequest(url: url)
            if let connection = NSURLConnection(request: request, delegate: self, startImmediately: false) {
                connection.schedule(in: RunLoop.current, forMode: RunLoopMode.commonModes)
                connection.start()
                print("Connection started", terminator: "\n")
                infoTextField.stringValue = "Connecting..."
            }
        }
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        infoTextField.textColor = NSColor.red
        infoTextField.stringValue = error.localizedDescription
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        infoTextField.textColor = NSColor.textColor
        infoTextField.stringValue = "Successful"
    }
 
    func connection(_ connection: NSURLConnection, willSendRequestFor challenge: URLAuthenticationChallenge) {
        NSLog("willSendRequestForAuthenticationChallenge for \(challenge.protectionSpace.authenticationMethod)")
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                
                var evaluateResult : SecTrustResultType = .invalid;
                let status = SecTrustEvaluate(serverTrust, &evaluateResult);
                
                if (status == errSecSuccess)  && (evaluateResult == .proceed  || evaluateResult == .unspecified ) {
                    NSLog("Certificate is trusted")
                }
                else
                {
                    NSLog("Certificate is not trusted")
                }
                certificates = [SecCertificate]()
                let certCount = SecTrustGetCertificateCount(serverTrust)
                NSLog("number certificate in serverTrust: \(certCount)");
                
                for index in 0 ..< certCount {
                    if let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, index) {
                        
                        let summary = SecCertificateCopySubjectSummary(serverCertificate)
                        NSLog("  server certificate: \(summary)")
                        
                        let cdata = SecCertificateCopyData(serverCertificate)
                        if let cert = SecCertificateCreateWithData(nil, cdata) {

                            certificates!.append(cert)
                        }
                    }
                }
                tableView.reloadData()
                enableButtons()
            }
        }
        
        challenge.sender?.performDefaultHandling!(for: challenge)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        return certificates?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let result = tableView.make(withIdentifier: "DataCell", owner: self) as? NSTableCellView {
            if certificates != nil {
                let summary = SecCertificateCopySubjectSummary(certificates![row]) as String
                result.textField!.stringValue = summary
            }
            return result
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return nil;
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        enableButtons()
    }

    override func controlTextDidChange(_ obj: Notification) {
        enableGetServerDataButton()
    }
}
