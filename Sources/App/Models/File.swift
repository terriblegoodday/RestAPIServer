//
//  File.swift
//  
//
//  Created by Eduard Dzhumagaliev on 30.01.2022.
//

import Vapor

final class File: Content {
    var name: String
    var size: Int

    init(name: String, size: Int) {
        self.name = name
        self.size = size
    }
}
