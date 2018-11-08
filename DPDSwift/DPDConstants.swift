//
//  DPDConstants.swift
//  DPDSwift
//
//  Created by Sylveus, Steeven on 11/8/18.
//

import UIKit

class DPDConstants: DPDObject {
    
    public static let shared = DPDConstants()
    
    static var rootUrl: String!
    static var accessTokenRefreshEndPoint: String?
    static var expiredAccessTokenErrorCode: Int?
    static var getAccessoTokenEndpoint: String?
    
    private override init() {
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
