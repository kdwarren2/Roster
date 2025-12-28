//
//  Item.swift
//  RosterScanner
//
//  Created by Keith Warren on 12/28/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
