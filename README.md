# DPDSwift

Deployd is a tool that makes building APIs simple by providing important ready-made functionality out of the box that meet the demands of complex applications.
DPDSwift is an iOS library, that helps facilitate the use of Deployd for iOS Development.

#Features
- DPDObject
- DPDUsers
- DPDQuery
- DPDRequest

#The Basics
- DPDSwift Uses ObjectMapper Library for object mapping. More information can be found here.  
-https://github.com/Hearst-DD/ObjectMapper

-Assuming we have a collection on Deployd called Stores.  We can access the store collection as follow.

-Using DPDObject
```swift
import UIKit
import DPDSwift
import ObjectMapper

class Store: DPDObject {
    var name: String?
    var city: String?
    var state: String?
    var zip: String?
    
    required init() {
        super.init()
    }
    
    required init?(_ map: Map) {
        super.init(map)
    }
    
    override func mapping(map: Map) {
        super.mapping(map)
        
        name <- map["name"]
        city <- map["city"]
        state <- map["state"]
        zip <- map["zip"]
    }
}


//================================ Inside View Controller =============================================
import UIKit
import DPDSwift

class ViewController: UIViewController {
    let rootUrl = "http://localhost:2403/"
    let store = Store()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func createStore() {
        store.name = "Best Buy"
        store.city = "Crystal Lake"
        store.state = "IL"
        store.zip = "60012"
        
        store.createObject(Store(), rootUrl: rootUrl, endPoint: "stores") { (response, responseHeader, error) in
            if error == nil {
                print("store created successfully")
            } else {
                print("failed to create store")
            }
        }
    }
    
    func updateStoreCollection() {
        store.name = "Apple"
        store.updateObjectInBackground(Store(), rootUrl: rootUrl, endPoint: "stores") { (response, responseHeader, error) in
            if error == nil {
                print("store updated successfully")
            } else {
                print("failed to create store")
            }
        }
    }
 }
```  
# Using DPDUser
