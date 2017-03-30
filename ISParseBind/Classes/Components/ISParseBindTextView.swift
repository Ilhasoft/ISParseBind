//
//  ISParseTextView.swift
//  Pods
//
//  Created by Daniel Amaral on 13/08/16.
//
//

import UIKit

open class ISParseBindTextView: UITextView, ISParseBindable {

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
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
            let index = self.layer.sublayers?.index {($0.frame.height == 1)}
            if let index = index {
                self.layer.sublayers?.remove(at: index)
            }
        }else {
            let bottomLine = CALayer()
            bottomLine.frame = CGRect(x: 0, y: self.frame.height - 1, width: self.frame.width, height: 1)
            bottomLine.backgroundColor = color.cgColor
            self.layer.addSublayer(bottomLine)
        }
    }
    
}
