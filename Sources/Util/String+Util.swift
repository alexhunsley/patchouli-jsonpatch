//
//  String+Util.swift
//  PatchouliJSON
//
//  Created by Alex Hunsley on 23/06/2024.
//

import Foundation

extension String {
    public var utf8Data: Data { Data(self.utf8) }
}
