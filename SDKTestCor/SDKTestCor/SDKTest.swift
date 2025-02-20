//
//  SDKTest.swift
//  SDKTestCor
//
//  Created by Serhii Molodets on 20.02.2025.
//
import Foundation
import Coralogix

public struct CallCoralogix {
    public static func call() {
        let options = CoralogixExporterOptions(
            coralogixDomain: .EU2,
            userContext: nil,
            environment: "config.environment.name",
            application: "dazn-sdk-stage",
            version: "SDKMetadata.version",
          
            publicKey: "Secrets.decodedCoralogixKey", //Secrets.coralogixKey,
            debug: false)
        let coralogixRum = CoralogixRum(options: options)
        
        coralogixRum.initializeCrashInstumentation()
        
    }
}


