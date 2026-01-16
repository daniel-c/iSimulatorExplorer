//
//  ImportCertificateView.swift
//  iSimulatorExplorer
//
//  Created by Daniel Cerutti on 16.01.2026.
//

import SwiftUI

struct CertificateItem: Identifiable {
    var id : String
    var subject : String
    var fingerprint : String
    var certificate : SecCertificate
}


@Observable class ImportSimulatorViewModel : NSObject, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    
    var infoText: String = ""
    var isError: Bool = false
    var certificates: [CertificateItem] = []
    var certificate: SecCertificate? = nil
    
    func getServerCertificates(url: String) {
        if let url = URL(string: "https://" + url) {
            print("url scheme: \(String(describing: url.scheme)) absolute: \(url.absoluteString)", terminator: "\n")
            let request = URLRequest(url: url)
            if let connection = NSURLConnection(request: request, delegate: self, startImmediately: false) {
                connection.schedule(in: RunLoop.current, forMode: RunLoop.Mode.common)
                connection.start()
                print("Connection started", terminator: "\n")
                isError = false
                infoText = "Connecting..."
            }
        }
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        isError = true
        infoText = error.localizedDescription
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        isError = false
        infoText = "Successful"
    }
 
    func connection(_ connection: NSURLConnection, willSendRequestFor challenge: URLAuthenticationChallenge) {
        NSLog("willSendRequestForAuthenticationChallenge for \(challenge.protectionSpace.authenticationMethod)")
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                
                var evaluateError : CFError?
                let status = SecTrustEvaluateWithError(serverTrust, &evaluateError);
                if (status) {
                    NSLog("Certificate is trusted")
                }
                else
                {
                    NSLog("Certificate is not trusted")
                }
                
                if let certs = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] {
                    NSLog("number certificate in serverTrust: \(certs.count)");
                    for serverCertificate in certs {
                        
                        let summary = SecCertificateCopySubjectSummary(serverCertificate)
                        NSLog("  server certificate: \(String(describing: summary))")
                        
                        let cdata = SecCertificateCopyData(serverCertificate)
                        if let cert = SecCertificateCreateWithData(nil, cdata) {
                            
                            let trustStoreCert = DCSimulatorTruststoreItem(certificate: cert)
                            let subject = trustStoreCert.subjectSummary
                            let fingerprint = trustStoreCert.getThumbprintAsHexString()
                            guard (certificates.first(where: { $0.fingerprint ==  fingerprint}) == nil) else {
                                continue
                            }
                            
                            certificates.append(CertificateItem(id: UUID().uuidString, subject: subject ?? "(Unknown)", fingerprint: fingerprint,  certificate: cert))
                        }
                    }
                }
            }
        }
        
        challenge.sender?.performDefaultHandling!(for: challenge)
    }
    
}


struct ImportCertificateView: View {
    @Environment(\.dismiss) var dismiss
    @State private var url: String = ""
    @State private var viewModel : ImportSimulatorViewModel = ImportSimulatorViewModel()
    @State private var seletectedCertificateId: String? = nil
    let trustStoreViewModel : SimulatorTrustStoreViewModel


    var body: some View {
        HStack(){
            Text("https://")
            TextField("example.com", text: $url)
            Button("Get") {
                viewModel.getServerCertificates(url: url)
                
            }.disabled(url.isEmpty)
        }.padding(10)
        Text(viewModel.infoText).foregroundStyle(viewModel.isError ? .red : .primary)
            .frame(height: 30)
        HStack() {
            Spacer().frame(width: 10)
            Text("SSL certificate chain")
            Spacer()
        }
        Table(viewModel.certificates, selection: $seletectedCertificateId) {
            TableColumn("Subject", value: \.subject).width(min: 50, ideal: 100, max: 100)
            TableColumn("Fingerprint", value: \.fingerprint)
        }
        HStack() {
            Spacer()
            Button("Cancel") {
                dismiss()
            }.frame(width: 130, alignment: .trailing)
            Button("Import") {
                if let certificate = viewModel.certificates.first(
                    where: { $0.id == seletectedCertificateId })?.certificate {
                    trustStoreViewModel.importCertificateFromServer(certificate: certificate)
                }

                dismiss()
            }.frame(width: 130, alignment: .trailing)
                .disabled(seletectedCertificateId == nil)
        }.padding(10)
    }
}

#Preview {
    ImportCertificateView(trustStoreViewModel:  SimulatorTrustStoreViewModel())
}
