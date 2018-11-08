# DPDSwift

Deployd is a tool that makes building APIs simple by providing important ready-made functionality out of the box that meet the demands of complex applications (http://deployd.com).
DPDSwift is an iOS library, that helps facilitate the use of Deployd for iOS Development.

#Features
- DPDObject
- DPDUser (Login, Logout)
- DPDQuery
- DPDRequest

#The Basics
- Assuming we have a collection on Deployd called Stores.  We can access the store collection as follow.

- Using DPDObject
```swift
import UIKit
import DPDSwift
import ObjectMapper

class Store: DPDObject {
    
    var name: String?
    var city: String?
    var state: String?
    var zip: String?
    
    override init() {
        super.init()
    }
    
    private enum CodingKeys: String, CodingKey {
        case name
        case city
        case state
        case zip
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try? container.decode(String.self, forKey: .name)
        self.city = try? container.decode(String.self, forKey: .city)
        self.state = try? container.decode(String.self, forKey: .state)
        self.zip = try? container.decode(String.self, forKey: .zip)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(name, forKey: .name)
        try? container.encode(city, forKey: .city)
        try? container.encode(state, forKey: .state)
        try? container.encode(zip, forKey: .zip)
        try? super.encode(to: encoder)
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
        let store = Store()
        store.name = "Best Buy"
        store.city = "Crystal Lake"
        store.state = "IL"
        store.zip = "60012"
        
        store.create(Store.self, endPoint: "store") { (response, headers, error) in
            if error == nil {
                //do something with store
            }
        }
    }
    
    func updateStore(store: Store) {
        store.update(Store.self, endPoint: "stores") { (response, headers, error) in
            if error == nil {
                //Store was updated
            }
        }
    }
 
 
 
 //========= If you want the response to be mapped to specific DPDObject, you can call the findMappableObject() otherwise call the findObject() method ===============
func getStores() {
        let query = DPDQuery(ordertype: .ascending,
                             limit: nil, skip: nil,
                             queryField: nil,
                             queryFieldValue: nil,
                             sortField: nil)
        query.findMappableObject(Store.self, endPoint: "stores") { (response, error) in
            if error == nil {
                
            }
        }
 }
    
```  
# Using DPDUser

- SubClassing DPDUser 

```swift
import UIKit
import DPDSwift

 class User: DPDUser {
 
    var name: String?
    var firstName: String?
    var lastName: String?
    var imageUrl: String?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case firstName
        case lastName
        case imageUrl
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try? container.decode(String.self, forKey: .name)
        self.firstName = try? container.decode(String.self, forKey: .firstName)
        self.lastName = try? container.decode(String.self, forKey: .lastName)
        self.imageUrl = try? container.decode(String.self, forKey: .imageUrl)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(name, forKey: .name)
        try? container.encode(firstName, forKey: .firstName)
        try? container.encode(lastName, forKey: .lastName)
        try? container.encode(imageUrl, forKey: .imageUrl)
        try? super.encode(to: encoder)
    }
}

//========================== Creating a User Collection ===============================
func createUser() {
    DPDUser.create(User.self, username: "test@gmail.com", password: "test") { (response, headers, error) in
        if error == nil {
            //do something with response
        }
    }
 }
    
func updateUser(user: User) {
    user.update(User.self) { (response, headers, error) in
        if error == nil {
        }
    }
 }
```
# Installation
DPDSwift can be added to your project using [CocoaPods 0.36 or later](http://blog.cocoapods.org/Pod-Authors-Guide-to-CocoaPods-Frameworks/) by adding the following line to your `Podfile`:

```ruby
pod 'DPDSwift', :git => 'https://github.com/ssylveus/DPDSwift.git', :branch => 'master'
```
