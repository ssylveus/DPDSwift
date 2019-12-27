//
//  DPDClient.swift
//  DPDSwift
//
//  Created by Sylveus, Steeven on 11/8/18.
//

import UIKit

public class DPDClient: DPDObject {
    
    static let firstInstallKey = "DPDFreshInstall"
    
    static var isFirstInstall: Bool {
        if UserDefaults.standard.string(forKey: firstInstallKey) == nil {
            return true
        }
        
        return true
    }
    
    private override init() {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    public static func initialize(rootUrl: String, accessTokenRefreshEndPoint: String? = nil, expiredAccessTokenErrorCode: Int? = nil, getAccessoTokenEndpoint: String? = nil, clearCredsOnFreshInstall: Bool = true) {
        
        if clearCredsOnFreshInstall && isFirstInstall {
            UserDefaults.standard.set(firstInstallKey, forKey: firstInstallKey)
            DPDKeyChain.clear()
        }
        
        DPDConstants.rootUrl = rootUrl
        DPDConstants.accessTokenRefreshEndPoint = accessTokenRefreshEndPoint
        DPDConstants.expiredAccessTokenErrorCode = expiredAccessTokenErrorCode
        DPDConstants.getAccessoTokenEndpoint = getAccessoTokenEndpoint
    }
    
    
}
