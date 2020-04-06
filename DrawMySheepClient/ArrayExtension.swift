//
//  ArrayExtension.swift
//  DrawMySheepClient
//
//  Created by  on 10/03/2020.
//  Copyright © 2020 clementdumas. All rights reserved.
//

import Foundation
extension Array {
    public func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Array where Element == UInt8 {
    var data: Data { return Data(self) }
}
