//
//  ISParseStringExtension.swift
//  Pods
//
//  Created by Daniel Amaral on 19/07/16.
//
//

import UIKit

extension String {

    public var capitalizeFirst: String {
        if isEmpty { return "" }
        var result = self
        result.replaceSubrange(startIndex...startIndex, with: String(self[startIndex]).uppercased())
        return result
    }
    
    public var uncapitalizeFirst: String {
        if isEmpty { return "" }
        var result = self
        result.replaceSubrange(startIndex...startIndex, with: String(self[startIndex]).lowercased())
        return result
    }
}
