//
//  Created by Drew McCormack on 21/04/2020.
//

import Foundation


public struct ReplicatingArray<T> {
    
    fileprivate struct ValueContainer: Identifiable {
        var anchor: ID?
        var value: T
        var lamportTimestamp: UInt64
        var id: UUID = UUID()
        var isDeleted: Bool = false
        
        init(anchor: ValueContainer.ID?, value: T, lamportTimestamp: UInt64) {
            self.anchor = anchor
            self.value = value
            self.lamportTimestamp = lamportTimestamp
        }
        
        func ordered(beforeSibling other: ValueContainer) -> Bool {
            (lamportTimestamp, id.uuidString) > (other.lamportTimestamp, other.id.uuidString)
        }
    }
    
    private var valueContainers: Array<ValueContainer> = []
    private var tombstones: Array<ValueContainer> = []
    
    public var values: Array<T> { valueContainers.map { $0.value } }
    public var count: UInt64 { UInt64(valueContainers.count) }
    
    private var lamportTimestamp: UInt64 = 0
    private mutating func tick() { lamportTimestamp += 1 }
        
    
    // MARK: Init
    
    public init() {}
    
}


// MARK: Adding and Updating ValueContainers

public extension ReplicatingArray {
        
    mutating func insert(_ newValue: T, at index: Int) {
        tick()
        let new = makeValueContainer(withValue: newValue, forInsertingAtIndex: index)
        valueContainers.insert(new, at: index)
    }
    
    mutating func append(_ newValue: T) {
        insert(newValue, at: valueContainers.count)
    }
    
    private func makeValueContainer(withValue value: T, forInsertingAtIndex index: Int) -> ValueContainer {
        let anchor = index > 0 ? valueContainers[index-1].id : nil
        let new = ValueContainer(anchor: anchor, value: value, lamportTimestamp: lamportTimestamp)
        return new
    }
}


// MARK: Removing ValueContainers

public extension ReplicatingArray {
        
    @discardableResult mutating func remove(at index: Int) -> T {
        var tombstone = valueContainers[index]
        tombstone.isDeleted = true
        tombstones.append(tombstone)
        valueContainers.remove(at: index)
        return tombstone.value
    }
    
}


// MARK: Merging

extension ReplicatingArray {
        
    public func merged(with other: Self) -> Self {
        let resultTombstones = (tombstones + other.tombstones).filterDuplicates { $0.id }
        let tombstoneIds = resultTombstones.map { $0.id }
        
        var encounteredIds: Set<ValueContainer.ID> = []
        let unorderedValueContainers = (valueContainers + other.valueContainers).filter {
            !tombstoneIds.contains($0.id) && encounteredIds.insert($0.id).inserted
        }
        
        let resultValueContainersWithTombstones = Self.ordered(fromUnordered: unorderedValueContainers + resultTombstones)
        let resultValueContainers = resultValueContainersWithTombstones.filter { !$0.isDeleted }
        
        var result = self
        result.valueContainers = resultValueContainers
        result.tombstones = resultTombstones
        result.lamportTimestamp = Swift.max(self.lamportTimestamp, other.lamportTimestamp)
        return result
    }

    /// Not just sorted, but ordered according to a preorder traversal of the tree.
    /// For each element, we insert the element itself first, then the child (anchored) subtrees from left to right.
    private static func ordered(fromUnordered unordered: [ValueContainer]) -> [ValueContainer] {
        let sorted = unordered.sorted { $0.ordered(beforeSibling: $1) }
        let anchoredByAnchorId: [ValueContainer.ID? : [ValueContainer]] = .init(grouping: sorted) { $0.anchor }
        var result: [ValueContainer] = []
        
        func addDecendants(of containers: [ValueContainer]) {
            for container in containers {
                result.append(container)
                guard let anchoredToValueContainer = anchoredByAnchorId[container.id] else { continue }
                addDecendants(of: anchoredToValueContainer)
            }
        }
        
        let roots = anchoredByAnchorId[nil] ?? []
        addDecendants(of: roots)
        return result
    }

}


// MARK: Codable

extension ReplicatingArray: Codable where T: Codable {
}

extension ReplicatingArray.ValueContainer: Codable where T: Codable {
}


// MARK: Equatable and Hashable

extension ReplicatingArray: Equatable where T: Equatable {
}

extension ReplicatingArray.ValueContainer: Equatable where T: Equatable {
}

extension ReplicatingArray: Hashable where T: Hashable {
}

extension ReplicatingArray.ValueContainer: Hashable where T: Hashable {
}


// MARK: Expressible as Array Literal

extension ReplicatingArray: ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: T...) {
        elements.forEach { self.append($0) }
    }
    
}


// MARK: Collection and RandomAccessCollection

extension ReplicatingArray: Collection, RandomAccessCollection {

    public var startIndex: Int { return valueContainers.startIndex }
    public var endIndex: Int { return valueContainers.endIndex }
    public func index(after i: Int) -> Int { valueContainers.index(after: i) }
    
    public subscript(_ i: Int) -> T {
        get {
            valueContainers[i].value
        }
        set {
            remove(at: i)
            tick()
            let newValueContainer = makeValueContainer(withValue: newValue, forInsertingAtIndex: i)
            valueContainers.insert(newValueContainer, at: i)
        }
    }
}


// MARK: Other

private extension Array {
    
    func filterDuplicates(identifyingWith block: (Element)->AnyHashable) -> Self {
        var encountered: Set<AnyHashable> = []
        return filter { encountered.insert(block($0)).inserted }
    }

}
