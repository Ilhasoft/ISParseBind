//
//  ISParseBindSwitch.swift
//  ISParseBind
//
//  Created by Daniel Amaral on 26/03/17.
//  Copyright © 2017 Ilhasoft. All rights reserved.
//

import UIKit

open class ISParseBindSwitch: UISwitch, ISParseBindable {
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBInspectable open var required: Bool = false
    @IBInspectable open var requiredError: String = ""
    @IBInspectable open var fieldType: String = ""
    @IBInspectable open var fieldTypeError: String = ""
    @IBInspectable open var fieldPath: String = ""
    @IBInspectable open var persist: Bool = true
    
}
