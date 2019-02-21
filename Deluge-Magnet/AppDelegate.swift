//
//  AppDelegate.swift
//  Deluge Magnet
//
//  Created by Jalal Ouraigua on 21/02/2019.
//  Copyright © 2019 Jalal Ouraigua. All rights reserved.
//

import Cocoa

// For replacing system() command which is deprecated

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setMagnetHandler()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard !urls.isEmpty else { return }

        let data = runCommand(launchPath: "/usr/bin/pgrep", args: ["deluge"])
        if data.count == 0 {
            let _ = runCommand(launchPath: "/usr/bin/open", args: ["-a",  "Deluge"])
            sleep(10)
        }

        let deluge_console = "/Applications/Deluge.app/Contents/MacOS/deluge-console"
        let _ = urls.map({ let _ = runCommand(launchPath: deluge_console, args: ["add", $0.absoluteString]) })

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: { exit(EXIT_SUCCESS) })
    }

    func setMagnetHandler() {
        let currentHandler = LSCopyDefaultHandlerForURLScheme("magnet" as CFString)!.takeUnretainedValue() as String
        print("Current magnet handler: \(currentHandler).")
        guard
            let newHandler = Bundle.main.bundleIdentifier,
            let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        else {
            return
        }

        if currentHandler == newHandler.lowercased() {
            print("\(appName) is already registered to handle magnets.")
        } else {
            var retval: OSStatus = kLSUnknownErr
            retval = LSSetDefaultHandlerForURLScheme("magnet" as CFString, newHandler as CFString)
            print("Result: \(retval == 0 ? "Success" : "Failed")");
        }
    }

    func runCommand(launchPath: String?, args: [String]?) -> Data {
        let process = Process()
        process.launchPath = launchPath
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        process.waitUntilExit()

        return pipe.fileHandleForReading.readDataToEndOfFile()
    }

}

