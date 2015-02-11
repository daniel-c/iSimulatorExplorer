### What is iSimulatorExplorer? ###

* iSimulatorExplorer is a simple application to browse the available iOS Simulators on your system and to quickly open applications program and data folder. Additionaly iSimulatorExplorer can easily add/remove trusted certificate on iOS Simulators. This make it easy for example to test applications connecting to development server with self-signed certificates as importing CA certificates is not directly supported in the iOS simulator.

![iSimulatorExplorer screen](img/screen1.jpg)

* iSimulatorExplorer is written in Swift and is a good example of how accessing undocumented API using late-binding can be achieved in Swift. 

### System requirements ###

* OS X 10.9 or 10.10
* Xcode 6.0 or above

### Notes on CA certificates in iOS simulator ###

* The trusted certificate management in iOS simulator is based on the [ADVTrustStore project](https://github.com/ADVTOOLS/ADVTrustStore) I have written 2 years ago, mainly on the documentation on the TrustStore.sqlite3 database format.

* To make it easy to test certificate imported with this tool, a sample iOS application is provided in this project: TestTrustedCertificate. It consist of a simple WebView to test a SSL connection to a server with a certificate not signed by a valid CA.

### Copyright and license ###

Copyright (c) 2015, Daniel Cerutti. Licensed under the MIT license. See LICENSE file in this project.