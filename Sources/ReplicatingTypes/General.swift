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
