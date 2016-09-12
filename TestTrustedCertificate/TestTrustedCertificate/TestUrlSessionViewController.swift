//
//  TestUrlSessionViewController.swift
//  TestTrustedCertificate
//
//  Created by Daniel Cerutti on 12/11/15.
//  Copyright © 2014-2016 Daniel Cerutti. All rights reserved.
//  Licensed under the MIT license. See LICENSE file in the project root for full license information.
//

import UIKit

class TestUrlSessionViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        webView.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    @IBAction func openUrlButton(sender: AnyObject) {
        if let text = urlTextField.text {
            urlTextField.resignFirstResponder()
            if let url = URL(string: text){
                
                let session = URLSession.init(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: OperationQueue.main)
                
                session.dataTask(with: url, completionHandler: { (data : Data?, response : URLResponse?, error : Error?) -> Void in
                    if error != nil {
                        let text = "<html><header></header><body><h2 style=\"color:red\">\(error!.localizedDescription)</h2><p>\(error!)<p></body></html>"
                        self.webView.loadHTMLString (text, baseURL:URL(string:"localhost"))
                    }
                    else
                    {
                        let mimeType = (response?.mimeType != nil) ? response!.mimeType! : "text/html"
                        let encoding = (response?.textEncodingName != nil) ? response!.textEncodingName! : "utf-8"
                        
                        self.webView.load(data!, mimeType: mimeType, textEncodingName: encoding, baseURL: url)
                    }
                }).resume()
            }
        }
    }
    
}

