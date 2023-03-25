import Foundation

@objc open class SwiftEventBus:NSObject {
    
    struct Static {
        static let instance = SwiftEventBus()
        static let queue = DispatchQueue(label: "com.cesarferreira.SwiftEventBus", attributes: [])
    }
    
    struct NamedObserver {
        let observer: NSObjectProtocol
        let name: String
    }
    
    var cache = [UInt:[NamedObserver]]()
    
    
    ////////////////////////////////////
    // Publish
    ////////////////////////////////////
    
    
    @objc open class func post(_ name: String, sender: Any? = nil) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: sender)
    }
    
    @objc open class func postNSObject(_ name: String, sender: NSObject?) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: sender)
    }
    
    @objc open class func post(_ name: String, sender: Any? = nil, userInfo: [AnyHashable: Any]?) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: sender, userInfo: userInfo)
    }
    
    @objc open class func postToMainThread(_ name: String, sender: Any? = nil) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: sender)
        }
    }
    
    @objc open class func postToMainThreadNSObject(_ name: String, sender: NSObject?) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: sender)
        }
    }
    
    @objc open class func postToMainThread(_ name: String, sender: Any? = nil, userInfo: [AnyHashable: Any]?) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: sender, userInfo: userInfo)
        }
    }
    
    
    
    ////////////////////////////////////
    // Subscribe
    ////////////////////////////////////
    
    @discardableResult
    @objc open class func on(_ target: AnyObject, name: String, sender: Any? = nil, queue: OperationQueue?, handler: @escaping ((Notification?) -> Void)) -> NSObjectProtocol {
        let id = UInt(bitPattern: ObjectIdentifier(target))
        let observer = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: name), object: sender, queue: queue, using: handler)
        let namedObserver = NamedObserver(observer: observer, name: name)
        
        Static.queue.sync {
            if let namedObservers = Static.instance.cache[id] {
                Static.instance.cache[id] = namedObservers + [namedObserver]
            } else {
                Static.instance.cache[id] = [namedObserver]
            }
        }
        
        return observer
    }
    
    @discardableResult
    @objc open class func onMainThread(_ target: AnyObject, name: String, sender: Any? = nil, handler: @escaping ((Notification?) -> Void)) -> NSObjectProtocol {
        return SwiftEventBus.on(target, name: name, sender: sender, queue: OperationQueue.main, handler: handler)
    }
    
    @discardableResult
    @objc open class func onBackgroundThread(_ target: AnyObject, name: String, sender: Any? = nil, handler: @escaping ((Notification?) -> Void)) -> NSObjectProtocol {
        return SwiftEventBus.on(target, name: name, sender: sender, queue: OperationQueue(), handler: handler)
    }
    
    ////////////////////////////////////
    // Unregister
    ////////////////////////////////////
    
    @objc open class func unregister(_ target: AnyObject) {
        let id = UInt(bitPattern: ObjectIdentifier(target))
        let center = NotificationCenter.default
        
        Static.queue.sync {
            if let namedObservers = Static.instance.cache.removeValue(forKey: id) {
                for namedObserver in namedObservers {
                    center.removeObserver(namedObserver.observer)
                }
            }
        }
    }
    
    @objc open class func unregister(_ target: AnyObject, name: String) {
        let id = UInt(bitPattern: ObjectIdentifier(target))
        let center = NotificationCenter.default
        
        Static.queue.sync {
            if let namedObservers = Static.instance.cache[id] {
                Static.instance.cache[id] = namedObservers.filter({ (namedObserver: NamedObserver) -> Bool in
                    if namedObserver.name == name {
                        center.removeObserver(namedObserver.observer)
                        return false
                    } else {
                        return true
                    }
                })
            }
        }
    }
    
}
