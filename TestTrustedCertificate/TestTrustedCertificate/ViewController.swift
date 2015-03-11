//
//  ViewController.swift
//  TestTrustedCertificate
//
//  Created by Daniel Cerutti on 11/10/14.
//  Copyright (c) 2014 Daniel Cerutti. All rights reserved.
//  Licensed under the MIT license. See LICENSE file in the project root for full license information.
//

import UIKit

class ViewController: UIViewController, UIWebViewDelegate {

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
            if let url = NSURL(string: text){
                let request = NSURLRequest(URL: url)
                webView.loadRequest(request)
            }
        }
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        let text = "<html><header></header><body><h2 style=\"color:red\">\(error.localizedDescription)</h2</body></html>"
        webView.loadHTMLString (text, baseURL:NSURL(string:"localhost"))
    }

}

