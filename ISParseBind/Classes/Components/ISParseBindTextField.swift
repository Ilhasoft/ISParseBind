//
//  ISTextField.swift
//  ISParse
//
//  Created by Daniel Amaral on 30/04/16.
//  Copyright © 2016 ilhasoft. All rights reserved.
//

import Foundation
import UIKit

open class ISParseBindTextField: UITextField, ISParseBindable {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        setupLayoutWithUnderline(color: underlineColor)
    }
    
    @IBInspectable open var required: Bool = false
    @IBInspectable open var underlineColor: UIColor = UIColor.clear {
        didSet {
            setupLayoutWithUnderline(color: underlineColor)
        }
    }
    @IBInspectable open var requiredError: String = ""
    @IBInspectable open var fieldType: String = ""
    @IBInspectable open var fieldTypeError: String = ""
    @IBInspectable open var fieldPath: String = ""
    @IBInspectable open var persist: Bool = true

    func setupLayoutWithUnderline(color:UIColor) {
        if color == UIColor.clear {
            self.layer.sublayers?.removeAll()
        }else {
            let bottomLine = CALayer()
            bottomLine.frame = CGRect(x: 0, y: self.frame.height - 1, width: self.frame.width, height: 1)
            bottomLine.backgroundColor = color.cgColor
            self.borderStyle = UITextBorderStyle.none
            self.layer.addSublayer(bottomLine)
        }
    }        
    
}
