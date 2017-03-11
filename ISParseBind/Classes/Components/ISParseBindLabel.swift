//
//  ISParseBindLabel.swift
//  ISParseBind
//
//  Created by Daniel Amaral on 11/03/17.
//  Copyright © 2017 Ilhasoft. All rights reserved.
//

import UIKit

open class ISParseBindLabel: UILabel, ISParseBindable {

    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public var required: Bool = false
    public var requiredError: String = ""
    public var fieldType: String = "Text"
    public var fieldTypeError: String = ""
    @IBInspectable open var fieldPath: String = ""
    public var persist: Bool = false

}
