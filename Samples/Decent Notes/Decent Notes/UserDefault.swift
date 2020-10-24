//
//  Utility.swift
//  Decent Notes
//
//  Created by Drew McCormack on 22/05/2020.
//  Copyright © 2020 Momenta B.V. All rights reserved.
//

import Foundation
import Combine

struct DefaultKey: RawRepresentable {
    let rawValue: String
}

@propertyWrapper class UserDefault<T>: NSObject, ObservableObject {
    let didChange = PassthroughSubject<UserDefault<T>, Never>()
    
    let key: DefaultKey
    let defaultValue: T?
    
    init(key: DefaultKey, defaultValue: T? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        super.init()
        if let defaultValue = self.defaultValue {
            UserDefaults.standard.register(defaults: [key.rawValue : defaultValue])
        }
        UserDefaults.standard.addObserver(self, forKeyPath: key.rawValue, options: [], context: nil)
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: key.rawValue)
    }
    
    var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key.rawValue) as! T
        } set {
            UserDefaults.standard.set(newValue, forKey: key.rawValue)
            UserDefaults.standard.synchronize()
            didChange.send(self)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        didChange.send(self)
    }
}
