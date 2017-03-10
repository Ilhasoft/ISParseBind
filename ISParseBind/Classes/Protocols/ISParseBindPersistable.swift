//
//  ISPersistable.swift
//  Pods
//
//  Created by Daniel Amaral on 30/06/16.
//
//

@objc public protocol ISParseBindPersistable {
    
    var required: Bool { get set }
    var requiredError: String { get set }
    var fieldType: String { get set }
    var fieldTypeError: String { get set }
    var fieldPath: String { get set }
    
}
