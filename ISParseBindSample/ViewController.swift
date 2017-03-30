//
//  ViewController.swift
//  ParsePersistence
//
//  Created by Daniel Amaral on 13/03/17.
//  Copyright © 2017 Ilhasoft. All rights reserved.
//

import UIKit
import ISParseBind
import MBProgressHUD

class ViewController: UIViewController {
    
    @IBOutlet var parseBindView:ISParseBindView!
    @IBOutlet var lbFabricationYear:UILabel!
    @IBOutlet var slider:ISParseBindSlider!
    
    var hud:MBProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        parseBindView.delegate = self
    }
    
    @IBAction func btSaveTapped() {
        hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud?.label.text = "Saving..."
        self.parseBindView.save()
    }
    
    @IBAction func sliderChanged(slider:UISlider) {
        self.lbFabricationYear.text = "\(Int(slider.value))"
    }
}

extension ViewController : ISParseBindViewDelegate {
    
    func didFetch(view: ISParseBindView, error: Error?) {
        
    }
    
    func willSave(view: ISParseBindView, object: PFObject) -> PFObject? {
        return object
    }
    
    func didSave(view: ISParseBindView, object: PFObject, isMainEntity: Bool, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            DispatchQueue.main.async {
                self.hud?.hide(animated: true)
            }
        }else {
            if isMainEntity == true {
                DispatchQueue.main.async {
                    self.hud?.label.text = "Main Entity did save \(object.parseClassName)"
                    self.hud?.hide(animated: true, afterDelay: 2)
                }
            }else {
                DispatchQueue.main.async {
                    self.hud!.label.text = "Saving \(object.parseClassName)"
                }
            }
        }
    }
    
    func willSet(component: Any, value: Any) -> Any? {
        if let component = component as? UISlider, component == slider {
            return Int(value as! Float)
        }
        return value
    }
    
    func didSet(component: Any, value: Any) {
        
    }
    
    func willFill(component: Any, value: Any) -> Any? {
        return value
    }
    
    func didFill(component: Any, value: Any) {
        
    }
    
}
