//
//  ReplicatingSet.swift
//
//
//  Created by Drew McCormack on 01/05/2020.
//

import Foundation

/// Observed-Remove Set. Can add and remove like a normal set.
/// This is more powerful than the other replicating sets, but has an extra storage cost.
/// Based on Convergent and commutative replicated data types by M Shapiro, N Preguiça, C Baquero, M Zawirski - 2011 - hal.inria.fr
public struct ReplicatingSet<T: Hashable> {
    
    fileprivate struct Metadata {
        var isDeleted: Bool
        var lamportTimestamp: LamportTimestamp
        
        init(lamportTimestamp: LamportTimestamp) {
            self.isDeleted = false
            self.lamportTimestamp = lamportTimestamp
        }
    }
    
    private var metadataByValue: Dictionary<T, Metadata>
    private var currentTimestamp: LamportTimestamp
    
    public var values: Set<T> {
        let values = metadataByValue.filter({ !$1.isDeleted }).map({ $0.key })
        return Set(values)
    }
    
    public var count: Int {
        metadataByValue.reduce(0) { result, pair in
            result + (pair.value.isDeleted ? 0 : 1)
        }
    }
        
    public init() {
        self.metadataByValue = .init()
        self.currentTimestamp = .init()
    }
    
    public init(array elements: [T]) {
        self = .init()
        elements.forEach { self.insert($0) }
    }
    
    @discardableResult public mutating func insert(_ value: T) -> Bool {
        currentTimestamp.tick()
        
        let metadata = Metadata(lamportTimestamp: currentTimestamp)
        let isNewInsert: Bool
        
        if let oldMetadata = metadataByValue[value] {
            isNewInsert = oldMetadata.isDeleted
        } else {
            isNewInsert = true
        }
        metadataByValue[value] = metadata
        
        return isNewInsert
    }
    
    @discardableResult public mutating func remove(_ value: T) -> T? {
        let returnValue: T?
    
        if let oldMetadata = metadataByValue[value], !oldMetadata.isDeleted {
            currentTimestamp.tick()
            var metadata = Metadata(lamportTimestamp: currentTimestamp)
            metadata.isDeleted = true
            metadataByValue[value] = metadata
            returnValue = value
        } else {
            returnValue = nil
        }
        
        return returnValue
    }
    
    public func contains(_ value: T) -> Bool {
        !(metadataByValue[value]?.isDeleted ?? true)
    }
}

extension ReplicatingSet: Replicable {
    
    public func merged(with other: ReplicatingSet) -> ReplicatingSet {
        var result = self
        result.metadataByValue = other.metadataByValue.reduce(into: metadataByValue) { result, entry in
            let firstMetadata = result[entry.key]
            let secondMetadata = entry.value
            if let firstMetadata = firstMetadata {
                result[entry.key] = firstMetadata.lamportTimestamp > secondMetadata.lamportTimestamp ? firstMetadata : secondMetadata
            } else {
                result[entry.key] = secondMetadata
            }
        }
        result.currentTimestamp = Swift.max(self.currentTimestamp, other.currentTimestamp)
        return result
    }
    
}

extension ReplicatingSet: Codable where T: Codable {
}

extension ReplicatingSet.Metadata: Codable where T: Codable {
}

extension ReplicatingSet: Equatable where T: Equatable {
}

extension ReplicatingSet.Metadata: Equatable where T: Equatable {
}

extension ReplicatingSet: Hashable where T: Hashable {
}

extension ReplicatingSet.Metadata: Hashable where T: Hashable {
}

extension ReplicatingSet: ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: T...) {
        self = .init(array: elements)
    }
    
}
