//
//  ReplicatingDictionaryTests.swift
//
//
//  Created by Drew McCormack on 26/04/2020.
//

import XCTest
@testable import ReplicatingTypes

final class ReplicatingDictionaryTests: XCTestCase {
    
    var a: ReplicatingDictionary<String, Int>!
    var b: ReplicatingDictionary<String, Int>!
    
    var dictOfSetsA: ReplicatingDictionary<String, ReplicatingSet<Int>>!
    var dictOfSetsB: ReplicatingDictionary<String, ReplicatingSet<Int>>!

    override func setUp() {
        super.setUp()
        a = .init()
        b = .init()
        dictOfSetsA = .init()
        dictOfSetsB = .init()
    }
    
    func testInitialCreation() {
        XCTAssertEqual(a.count, 0)
        XCTAssertEqual(dictOfSetsA.count, 0)
    }
    
    func testInserting() {
        a["1"] = 1
        a["2"] = 2
        a["3"] = 3
        XCTAssertEqual(a.values.sorted(), [1,2,3])
        XCTAssertEqual(a.keys.sorted(), ["1","2","3"])
    }

    func testReplacing() {
        a["1"] = 1
        a["2"] = 2
        a["3"] = 3
        XCTAssertEqual(a["2"], 2)

        a["2"] = 4
        XCTAssertEqual(a["2"], 4)
    }

    func testRemoving() {
        a["1"] = 1
        a["2"] = 2
        a["3"] = 3
        a["1"] = nil
        XCTAssertEqual(a.values.sorted(), [2,3])
        XCTAssertEqual(a.keys.sorted(), ["2","3"])
    }

    func testInterleavedInsertAndRemove() {
        a["1"] = 1
        a["2"] = 2
        a["3"] = 3
        
        a["2"] = nil
        XCTAssertNil(a["2"])

        a["2"] = 4
        a["3"] = 5
        XCTAssertEqual(a["2"], 4)
        XCTAssertEqual(a["3"], 5)

        a["2"] = nil
        a["2"] = nil
        a["3"] = 6
        XCTAssertNil(a["2"])
        XCTAssertEqual(a["3"], 6)
    }

    func testMergeOfInitiallyUnrelated() {
        a["1"] = 1
        a["2"] = 2
        a["3"] = 3
        a["6"] = 8

        // Force the lamport of b higher, so it comes first
        b["1"] = 4
        b["1"] = nil
        b["1"] = 4
        b["2"] = 5
        b["3"] = 6
        b["4"] = 7

        let c = a.merged(with: b)
        XCTAssertEqual(c.values.sorted(), [4,5,6,7,8])
    }

    func testMultipleMerges() {
        a["1"] = 1
        a["2"] = 2
        a["3"] = 3

        b = b.merged(with: a)

        // Force the lamport of b higher, so it comes first
        b["4"] = 4
        b["4"] = nil

        b["1"] = 10
        b["5"] = 11

        b["4"] = 12
        a["6"] = 12

        let c = a.merged(with: b)
        XCTAssertEqual(c.values.sorted(), [2,3,10,11,12,12])
        XCTAssertEqual(c.keys.sorted(), ["1","2","3","4","5","6"])
        XCTAssertEqual(c["1"], 10)
        XCTAssertEqual(c["4"], 12)
        XCTAssertEqual(c["6"], 12)
    }

    func testIdempotency() {
        a["1"] = 1
        a["2"] = 2
        a["3"] = 3
        a["2"] = nil
        
        b["1"] = 4
        b["1"] = nil
        b["1"] = 4
        b["3"] = 6
        b["2"] = nil

        let c = a.merged(with: b)
        let d = c.merged(with: b)
        let e = c.merged(with: a)
        XCTAssertEqual(c.dictionary, d.dictionary)
        XCTAssertEqual(c.dictionary, e.dictionary)
    }

    func testCommutivity() {
        a["1"] = 1
        a["2"] = 2
        a["3"] = 3
        a["2"] = nil
        
        b["1"] = 4
        b["1"] = nil
        b["1"] = 4
        b["3"] = 6
        b["2"] = nil

        let c = a.merged(with: b)
        let d = b.merged(with: a)
        XCTAssertEqual(c.dictionary, d.dictionary)
    }

    func testAssociativity() {
        a["1"] = 1
        a["2"] = 2
        a["3"] = 3
        a["2"] = nil
        
        b["1"] = 4
        b["1"] = nil
        b["1"] = 4
        b["3"] = 6
        b["2"] = nil

        var c = a!
        c["1"] = nil

        let e = a.merged(with: b).merged(with: c)
        let f = a.merged(with: b.merged(with: c))
        XCTAssertEqual(e.values, f.values)
    }
    
    func testNonAtomicMergingOfReplicatingValues() {
        dictOfSetsA["1"] = .init(array: [1,2,3])
        dictOfSetsA["2"] = .init(array: [3,4,5])
        dictOfSetsA["3"] = .init(array: [1])
        
        dictOfSetsB["1"] = .init(array: [1,2,3,4])
        dictOfSetsB["3"] = .init(array: [3,4,5])
        dictOfSetsB["1"] = nil
        dictOfSetsB["3"]!.insert(6)
        
        let dictOfSetC = dictOfSetsA.merged(with: dictOfSetsB)
        let dictOfSetD = dictOfSetsB.merged(with: dictOfSetsA)
        XCTAssertEqual(dictOfSetC["3"]!.values, [1,3,4,5,6])
        XCTAssertNil(dictOfSetC["1"])
        XCTAssertEqual(dictOfSetC["2"]!.values, [3,4,5])
        
        let valuesC = dictOfSetC.dictionary.values.flatMap({ $0.values }).sorted()
        let valuesD = dictOfSetD.dictionary.values.flatMap({ $0.values }).sorted()
        XCTAssertEqual(valuesC, valuesD)
    }

    func testCodable() {
        a["1"] = 1
        a["2"] = 2
        a["3"] = 3
        a["2"] = nil

        let data = try! JSONEncoder().encode(a)
        let d = try! JSONDecoder().decode(type(of: a!), from: data)
        XCTAssertEqual(d.dictionary, a.dictionary)
    }

}
