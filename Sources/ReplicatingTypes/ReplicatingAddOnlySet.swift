//
//  ReplicatingAddOnlySet.swift
//  
//
//  Created by Drew McCormack on 01/05/2020.
//

import Foundation

/// Add-Only Set. Cannot remove items, so it can only grow.
/// Based on Convergent and commutative replicated data types by M Shapiro, N Preguiça, C Baquero, M Zawirski - 2011 - hal.inria.fr
public struct ReplicatingAddOnlySet<T: Hashable> {
    
    private var storage: Set<T>
    
    public mutating func insert(_ entry: T) {
        storage.insert(entry)
    }
    
    public var values: Set<T> {
        storage
    }
    
    public init() {
        storage = .init()
    }
    
    public init(_ values: Set<T>) {
        storage = values
    }
}

extension ReplicatingAddOnlySet: Replicable {
    
    public func merged(with other: ReplicatingAddOnlySet) -> ReplicatingAddOnlySet {
        ReplicatingAddOnlySet(storage.union(other.storage))
    }
    
}

extension ReplicatingAddOnlySet: Codable where T: Codable {
}

extension ReplicatingAddOnlySet: Equatable where T: Equatable {
}

