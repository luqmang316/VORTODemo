//
//  CDYelpFusionKitManager.swift
//  VORTOApp
//
//  Created by Muhammad Luqman on 11/15/20.
//

import CDYelpFusionKit
import UIKit

final class CDYelpFusionKitManager: NSObject {

    static let shared = CDYelpFusionKitManager()

    var apiClient: CDYelpAPIClient!

    func configure() {
        // How to authorize using your clientId and clientSecret
        self.apiClient = CDYelpAPIClient(apiKey: "YYINVIlskelrxu9GvIGUisT6KNV0P7-lXNoQmEnf-IC-OXbmPMlmlFWV9RMjB1tZnDzQ60fm294wzlcKT_23JqbI5PGi5NqWh0POY4mg91J2FpXFSrIEjTygWm2xX3Yx")
        
    }
}
