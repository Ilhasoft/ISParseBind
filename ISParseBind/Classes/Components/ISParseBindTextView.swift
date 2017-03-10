//
//  ISParseTextView.swift
//  Pods
//
//  Created by Daniel Amaral on 13/08/16.
//
//

import UIKit

open class ISParseBindTextView: UITextView, ISParseBindPersistable {

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
    
    func setupLayoutWithUnderline(color:UIColor) {
        if color == UIColor.clear {
            self.layer.sublayers?.removeAll()
        }else {
            let bottomLine = CALayer()
            bottomLine.frame = CGRect(x: 0, y: self.frame.height - 1, width: self.frame.width, height: 1)
            bottomLine.backgroundColor = color.cgColor
//            self.borderStyle = UITextBorderStyle.none
            self.layer.addSublayer(bottomLine)
        }
    }
    
    public func willSetValue(value: Any) -> Any? {
        return value
    }
    
    public func didSetValue(value: Any) {
        
    }
}
