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
        importButton.enabled = (tableView.selectedRow >= 0)
    }
    
    func enableGetServerDataButton() {
        getServerDataButton.enabled = (urlTextField.stringValue != "")
    }
    
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        NSApplication.sharedApplication().stopModalWithCode(1)
        window!.close();
    }
    
    func windowShouldClose(sender: AnyObject) -> Bool {
        NSApplication.sharedApplication().stopModalWithCode(2)
        return true
    }

    @IBAction func importButtonPressed(sender: AnyObject) {
        if tableView.selectedRow >= 0 {
            certificate = certificates?[tableView.selectedRow]
        }
        NSApplication.sharedApplication().stopModalWithCode(0)
        window!.close();
    }

    @IBAction func getServerDataButtonPressed(sender: AnyObject) {
        if let url = NSURL(string: "https://" + urlTextField.stringValue) {
            print("url scheme: \(url.scheme) absolute: \(url.absoluteString)", terminator: "\n")
            let request = NSURLRequest(URL: url)
            if let connection = NSURLConnection(request: request, delegate: self, startImmediately: false) {
                connection.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
                connection.start()
                print("Connection started", terminator: "\n")
                infoTextField.stringValue = "Connecting..."
            }
        }
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        infoTextField.textColor = NSColor.redColor()
        infoTextField.stringValue = error.localizedDescription
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        infoTextField.textColor = NSColor.textColor()
        infoTextField.stringValue = "Successful"
    }
 
    func connection(connection: NSURLConnection, willSendRequestForAuthenticationChallenge challenge: NSURLAuthenticationChallenge) {
        NSLog("willSendRequestForAuthenticationChallenge for \(challenge.protectionSpace.authenticationMethod)")
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                
                var evaluateResult : SecTrustResultType = 0;
                let status = SecTrustEvaluate(serverTrust, &evaluateResult);
                
                if (status == errSecSuccess)  && (evaluateResult == 1 /* kSecTrustResultProceed */ || evaluateResult == 4 /*kSecTrustResultUnspecified */) {
                    NSLog("Certificate is trusted")
                }
                else
                {
                    NSLog("Certificate is not trusted")
                }
                certificates = [SecCertificate]()
                let certCount = SecTrustGetCertificateCount(serverTrust)
                NSLog("number certificate in serverTrust: \(certCount)");
                
                for var index = 0; index < certCount; index++ {
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
        
        challenge.sender?.performDefaultHandlingForAuthenticationChallenge!(challenge)
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        
        return certificates?.count ?? 0
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let result = tableView.makeViewWithIdentifier("DataCell", owner: self) as? NSTableCellView {
            if certificates != nil {
                let summary = SecCertificateCopySubjectSummary(certificates![row]) as String
                result.textField!.stringValue = summary
            }
            return result
        }
        return nil
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return nil;
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        enableButtons()
    }

    override func controlTextDidChange(obj: NSNotification) {
        enableGetServerDataButton()
    }
}
