//
//  ReplicatingDictionary.swift
//
//
//  Created by Drew McCormack on 01/05/2020.
//

import Foundation

/// A replicating dictionary.
public struct ReplicatingDictionary<Key, Value> where Key: Hashable {
    
    fileprivate struct ValueContainer {
        var isDeleted: Bool
        var lamportTimestamp: LamportTimestamp
        var value: Value
        
        init(value: Value, lamportTimestamp: LamportTimestamp) {
            self.isDeleted = false
            self.lamportTimestamp = lamportTimestamp
            self.value = value
        }
    }
    
    private var valueContainersByKey: Dictionary<Key, ValueContainer>
    private var currentTimestamp: LamportTimestamp
    
    private var existingKeyValuePairs: [(key: Key, value: ValueContainer)] {
        valueContainersByKey.filter({ !$0.value.isDeleted })
    }
    
    public var values: [Value] {
        let values = existingKeyValuePairs.map({ $0.value.value })
        return values
    }
    
    public var keys: [Key] {
        let keys = existingKeyValuePairs.map({ $0.key })
        return keys
    }
    
    public var dictionary: [Key : Value] {
        existingKeyValuePairs.reduce(into: [:]) { result, pair in
            result[pair.key] = pair.value.value
        }
    }
    
    public var count: Int {
        valueContainersByKey.reduce(0) { result, pair in
            result + (pair.value.isDeleted ? 0 : 1)
        }
    }
        
    public init() {
        self.valueContainersByKey = .init()
        self.currentTimestamp = .init()
    }
    
    public subscript(key: Key) -> Value? {
        get {
            guard let container = valueContainersByKey[key], !container.isDeleted else { return nil }
            return container.value
        }
        
        set(newValue) {
            currentTimestamp.tick()
            if let newValue = newValue {
                let container = ValueContainer(value: newValue, lamportTimestamp: currentTimestamp)
                valueContainersByKey[key] = container
            } else if let oldContainer = valueContainersByKey[key] {
                var newContainer = ValueContainer(value: oldContainer.value, lamportTimestamp: currentTimestamp)
                newContainer.isDeleted = true
                valueContainersByKey[key] = newContainer
            }
        }
    }
}

extension ReplicatingDictionary: Replicable {
    
    public func merged(with other: ReplicatingDictionary) -> ReplicatingDictionary {
        var result = self
        result.valueContainersByKey = other.valueContainersByKey.reduce(into: valueContainersByKey) { result, entry in
            let firstValueContainer = result[entry.key]
            let secondValueContainer = entry.value
            if let firstValueContainer = firstValueContainer {
                result[entry.key] = firstValueContainer.lamportTimestamp > secondValueContainer.lamportTimestamp ? firstValueContainer : secondValueContainer
            } else {
                result[entry.key] = secondValueContainer
            }
        }
        result.currentTimestamp = max(self.currentTimestamp, other.currentTimestamp)
        return result
    }
    
}

extension ReplicatingDictionary where Value: Replicable {
    
    /// If the values are themselves Replicable, we don't have to merge values atomically.
    /// Instead of just choosing one value or the other, we can merge the values themselves. This merge
    /// method does exactly that.
    public func merged(with other: ReplicatingDictionary) -> ReplicatingDictionary {
        var haveTicked = false
        var resultDictionary = self
        resultDictionary.currentTimestamp = max(self.currentTimestamp, other.currentTimestamp)
        resultDictionary.valueContainersByKey = other.valueContainersByKey.reduce(into: valueContainersByKey) { result, entry in
            let first = result[entry.key]
            let second = entry.value
            if let first = first {
                if !first.isDeleted, !second.isDeleted {
                    // Merge the values
                    if !haveTicked {
                        resultDictionary.currentTimestamp.tick()
                        haveTicked = true
                    }
                    let newValue = first.value.merged(with: second.value)
                    let newValueContainer = ValueContainer(value: newValue, lamportTimestamp: resultDictionary.currentTimestamp)
                    result[entry.key] = newValueContainer
                } else {
                    // At least one deletion, so just revert to atomic merge
                    result[entry.key] = first.lamportTimestamp > second.lamportTimestamp ? first : second
                }
            } else {
                result[entry.key] = second
            }
        }
        return resultDictionary
    }
    
}

extension ReplicatingDictionary: Codable where Value: Codable, Key: Codable {
}

extension ReplicatingDictionary.ValueContainer: Codable where Value: Codable, Key: Codable {
}

extension ReplicatingDictionary: Equatable where Value: Equatable {
}

extension ReplicatingDictionary.ValueContainer: Equatable where Value: Equatable {
}

extension ReplicatingDictionary: Hashable where Value: Hashable {
}

extension ReplicatingDictionary.ValueContainer: Hashable where Value: Hashable {
}
