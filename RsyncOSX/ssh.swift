//
//  ssh.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 23.04.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//


import Foundation
import Cocoa


class ssh: files {
    
    var commandCopyPasteTermninal:String?
    
    // Delegate for reporting file error if any to main view
    // Comply to protocol
    weak var error_delegate: ReportErrorInMain?
    
    // Local public rsa and dsa based keys
    let rsaPubKey:String = "id_rsa.pub"
    let dsaPubKey:String = "id_dsa.pub"
    let sshCatalog:String = ".ssh/"
    var dsaPubKeyExist:Bool = false
    var rsaPubKeyExist:Bool = false
    
    // Full URL paths to local public keys
    var rsaURLpath:URL?
    var dsaURLpath:URL?
    // Full String paths to local public keys
    var rsaStringPath:String?
    var dsaStringPath:String?
    
    // Arrays listing all key files
    var KeyFileURLS:Array<URL>?
    var KeyFileStrings:Array<String>?
    
    var scpArguments:scpArgumentsSsh?
    var command:String?
    var arguments:Array<String>?
    
    // Process
    var process:commandSsh?
    var output:outputProcess?
    
    // Chmod
    var chmod:chmodPubKey?
    
    // Create local rsa keys
    func createLocalKeysRsa() {
        
        // Abort if key exists
        guard self.rsaPubKeyExist == false else {
            return
        }
        
        self.scpArguments = nil
        self.scpArguments = scpArgumentsSsh(hiddenID: nil)
        self.arguments = scpArguments!.getArguments(operation: .createKey, key: "rsa", path: self.FilesRoot)
        self.command = self.scpArguments!.getCommand()
        self.executeSshCommand()
    }
    
    // Create local dsa keys
    func createLocalKeysDsa() {
        
        // Abort if key exists
        guard self.dsaPubKeyExist == false else {
            return
        }
        
        self.scpArguments = nil
        self.scpArguments = scpArgumentsSsh(hiddenID: nil)
        self.arguments = scpArguments!.getArguments(operation: .createKey, key: "dsa", path: self.FilesRoot)
        self.command = self.scpArguments!.getCommand()
        self.executeSshCommand()
    }
    
    // Check for local public keys
    func CheckForLocalPubKeys() {
        self.dsaPubKeyExist = self.IsLocalPublicKeysPresent(key: self.dsaPubKey)
        self.rsaPubKeyExist = self.IsLocalPublicKeysPresent(key: self.rsaPubKey)
    }
    
    // Check if rsa and/or dsa is existing in local .ssh catalog
    func IsLocalPublicKeysPresent (key:String) -> Bool {
        guard self.KeyFileStrings != nil else {
            return false
        }
        guard self.KeyFileStrings!.filter({$0.contains(key)}).count > 0 else {
            return false
        }
        switch key {
        case rsaPubKey:
            self.rsaURLpath = URL(string: self.KeyFileStrings!.filter({$0.contains(self.sshCatalog + key)})[0])
            self.rsaStringPath = self.KeyFileStrings!.filter({$0.contains(self.sshCatalog + key)})[0]
        case dsaPubKey:
            self.dsaURLpath = URL(string: self.KeyFileStrings!.filter({$0.contains(self.sshCatalog + key)})[0])
            self.dsaStringPath = self.KeyFileStrings!.filter({$0.contains(self.sshCatalog + key)})[0]
        default:
            return false
        }
        return true
    }
    
    // Secure copy of public key from local to remote catalog
    func ScpPubKey(key: String, hiddenID:Int) {
        self.scpArguments = nil
        self.scpArguments = scpArgumentsSsh(hiddenID: hiddenID)
        switch key {
        case "rsa":
            guard self.rsaStringPath != nil else {
                return
            }
            self.arguments = scpArguments!.getArguments(operation: .scpKey, key: key, path: self.rsaStringPath!)
        case "dsa":
            guard self.dsaStringPath != nil else {
                return
            }
            self.arguments = scpArguments!.getArguments(operation: .scpKey, key: key, path: self.dsaStringPath!)
        default:
            break
        }
        self.command = self.scpArguments!.getCommand()
        self.commandCopyPasteTermninal = self.scpArguments!.commandCopyPasteTermninal
    }
    
    // Check for remote pub keys
    func checkRemotePubKey(key: String, hiddenID:Int) {
        self.scpArguments = nil
        self.scpArguments = scpArgumentsSsh(hiddenID: hiddenID)
        switch key {
        case "rsa":
            guard self.rsaStringPath != nil else {
                return
            }
            self.arguments = scpArguments!.getArguments(operation: .checkKey, key: key, path: nil)
        case "dsa":
            guard self.dsaStringPath != nil else {
                return
            }
            self.arguments = scpArguments!.getArguments(operation: .checkKey, key: key, path: nil)
        default:
            break
        }
        self.command = self.scpArguments!.getCommand()
    }
    
    // Create remote ssh directory
    func createSshRemoteDirectory(hiddenID:Int) {
        self.scpArguments = nil
        self.scpArguments = scpArgumentsSsh(hiddenID: hiddenID)
        self.arguments = scpArguments!.getArguments(operation: .createRemoteSshCatalog, key: nil, path: nil)
        self.command = self.scpArguments!.getCommand()
        self.commandCopyPasteTermninal = self.scpArguments!.commandCopyPasteTermninal
    }
    
    // Chmod remote .ssh directory
    func chmodSsh(key: String, hiddenID:Int) {
        self.scpArguments = nil
        self.scpArguments = scpArgumentsSsh(hiddenID: hiddenID)
        self.arguments = scpArguments!.getArguments(operation: .chmod, key: key, path: nil)
        self.command = self.scpArguments!.getCommand()
        self.chmod = chmodPubKey(key:key)
    }
    
    // Execute command
    func executeSshCommand() {
        self.process = commandSsh(command: self.command, arguments: self.arguments)
        self.output = outputProcess()
        self.process!.executeProcess(output: self.output!)
    }
    
    // get output
    func getOutput() -> Array<String>? {
        return self.output?.getOutput()
    }
    
    // Open Terminal.app
    func openTerminal() {
        NSWorkspace.shared().open(URL(fileURLWithPath: "/Applications/Utilities/Terminal.app"))
    }
    
    init() {
        super.init(root: .sshRoot)
        self.KeyFileURLS = self.getFilesURLs()
        self.KeyFileStrings = self.getFileStrings()
        self.CheckForLocalPubKeys()
        self.createDirectory()
    }
    
}

extension ssh: ReportError {
    // Propagating any file error to main view
    func reportError(errorstr:String) {
        if let pvc = SharingManagerConfiguration.sharedInstance.ViewControllertabMain {
            self.error_delegate = pvc as? ViewControllertabMain
            self.error_delegate?.fileerror(errorstr: errorstr)
        }
    }
    
}