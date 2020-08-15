//
//  File.swift
//  
//
//  Created by Drew McCormack on 01/05/2020.
//

import Foundation

public protocol Replicable {
    func merged(with other: Self) -> Self
}

internal struct LamportTimestamp: Codable, Identifiable, Comparable, Hashable {
    var count: UInt64 = 0
    var id: UUID = UUID()
    
    public mutating func tick() {
        count += 1
        id = UUID()
    }
    
    static func < (lhs: LamportTimestamp, rhs: LamportTimestamp) -> Bool {
        (lhs.count, lhs.id.uuidString) < (rhs.count, rhs.id.uuidString)
    }
}
