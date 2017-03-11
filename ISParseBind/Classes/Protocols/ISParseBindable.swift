//
//  ISPersistable.swift
//  Pods
//
//  Created by Daniel Amaral on 30/06/16.
//
//

@objc public protocol ISParseBindable {
    
    var required: Bool { get set }
    var requiredError: String { get set }
    var fieldType: String { get set }
    var fieldTypeError: String { get set }
    var fieldPath: String { get set }
    var persist: Bool { get set }
    
    @objc optional func willSet(value:Any) -> Any?
    @objc optional func didSet(value:Any)
    @objc optional func willFill(value:Any) -> Any?
    @objc optional func didFill(value:Any)
    
}
