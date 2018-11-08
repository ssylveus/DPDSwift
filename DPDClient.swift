//
//  DPDClient.swift
//  DPDSwift
//
//  Created by Sylveus, Steeven on 11/8/18.
//

import UIKit

public class DPDClient: DPDObject {
    
    private override init() {
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    public static func initialize(rootUrl: String, accessTokenRefreshEndPoint: String? = nil, expiredAccessTokenErrorCode: Int? = nil, getAccessoTokenEndpoint: String? = nil) {
        DPDConstants.rootUrl = rootUrl
        DPDConstants.accessTokenRefreshEndPoint = accessTokenRefreshEndPoint
        DPDConstants.expiredAccessTokenErrorCode = expiredAccessTokenErrorCode
        DPDConstants.getAccessoTokenEndpoint = getAccessoTokenEndpoint
    }
    
    
}
