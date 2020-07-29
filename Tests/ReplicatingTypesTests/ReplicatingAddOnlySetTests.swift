//
//  ReplicatingAddOnlySetTests.swift
//
//
//  Created by Drew McCormack on 26/04/2020.
//

import XCTest
@testable import ReplicatingTypes

final class ReplicatingAddOnlySetTests: XCTestCase {
    
    var a: ReplicatingAddOnlySet<Int>!
    var b: ReplicatingAddOnlySet<Int>!

    override func setUp() {
        super.setUp()
        a = .init(Set(arrayLiteral: 1,2))
        b = .init(Set(arrayLiteral: 5))
    }
    
    func testInitialCreation() {
        XCTAssertEqual(a.values, Set(arrayLiteral: 1,2))
        XCTAssertEqual(b.values, Set(arrayLiteral: 5))
    }
    
    func testInsertingValue() {
        a.insert(3)
        XCTAssertEqual(a.values, Set(arrayLiteral: 1,2,3))
        a.insert(3)
        XCTAssertEqual(a.values, Set(arrayLiteral: 1,2,3))
    }

    func testMergeOfInitiallyUnrelated() {
        let c = a.merged(with: b)
        XCTAssertEqual(c.values, Set(arrayLiteral: 1,2,5))
    }

    func testIdempotency() {
        let c = a.merged(with: b)
        let d = c.merged(with: b)
        let e = c.merged(with: a)
        XCTAssertEqual(c.values, d.values)
        XCTAssertEqual(c.values, e.values)
    }

    func testCommutativity() {
        let c = a.merged(with: b)
        let d = b.merged(with: a)
        XCTAssertEqual(d.values, c.values)
    }

    func testAssociativity() {
        let c: ReplicatingAddOnlySet<Int> = .init(Set(arrayLiteral: 1,2,3))
        let e = a.merged(with: b).merged(with: c)
        let f = a.merged(with: b.merged(with: c))
        XCTAssertEqual(e.values, f.values)
    }

    func testCodable() {
        let data = try! JSONEncoder().encode(a)
        let d = try! JSONDecoder().decode(ReplicatingAddOnlySet<Int>.self, from: data)
        XCTAssertEqual(a, d)
    }
}
