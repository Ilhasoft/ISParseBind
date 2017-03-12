//
//  ISParseBindView.swift
//  Pods
//
//  Created by Daniel Amaral on 27/01/17.
//
//

import UIKit
import Parse
import Kingfisher

public protocol ISParseBindViewDelegate {
    func willSave(view:ISParseBindView,object:PFObject) -> PFObject?
    func didSave(view:ISParseBindView,object:PFObject,error:Error?)
    func allEntitiesDidSave(view:ISParseBindView,mainEntity:PFObject,error:Error?)
}

open class ISParseBindView: UIView {
    
    @IBOutlet open var fields:[AnyObject]!
    
    //fieldAndValues store fieldNames fieldValues of ISParseBindable fields
    private var fieldAndValues = [[String:Any]]()
    
    //currentKeyPath store fieldName keyPath separated by '.' that will be used on search that keys in PFQuery of fetchedParseObject
    private var currentKeyPath = [String]()
    
    //nextObjectQueue store PFObjects of relational className from main entity in fillFields loop
    private var nextObjectQueue = [PFObject]()
    
    private var lastSavedObjectList = [[String:PFObject]]()
    
    private var isFieldSorted = false
    
    open var includeKeys = [String]()
    open var mainEntity = ""
    open var imageCompression:CGFloat = 0.1
    
    open var parseObject:PFObject? {
        didSet {
            if self.fetchedParseObject == nil {
                self.prepareForFetchData()
            }
        }
    }
    private var fetchedParseObject:PFObject!
    
    public var delegate:ISParseBindViewDelegate?
    
    private func getParseFieldValue(field:AnyObject,fieldValue:AnyObject,fieldType:ISParseBindFieldType) -> Any {
        
        var fieldValue = fieldValue
        
        if field is UISlider {
            return fieldValue
        }
        
        if !(fieldValue is NSNull) {
            switch fieldType {
            case .Number:
                if let stringValue = fieldValue as? String {
                    fieldValue = stringValue.replacingOccurrences(of: ",", with: ".") as AnyObject
                }
                fieldValue = fieldValue.doubleValue as AnyObject
                return fieldValue
            case .Logic:
                print("fieldValue = .Logic\(fieldValue)")
                break
            case .Image:
                if let value = getFieldWithCast(fieldValue) as? PFFile {
                    fieldValue = value
                }else{
                    print("FieldType Image but the value is not a Image")
                }
                return fieldValue
            default:
                return fieldValue

            }
        }
        return NSNull()
    }
    
    private func getFieldWithCast(_ fieldValue:AnyObject) -> AnyObject{
        let value = fieldValue
        if let value = value as? UIImage {
            return PFFile(name: "image",data: UIImageJPEGRepresentation(value, self.imageCompression)!)!
        }else {
            return value
        }
    }
    
    private func buildIncludeKeys() {
        var keyPath = [String]()
        
        sortFields()
        for field in fields {
            let fieldNamePath = (field as! ISParseBindable).fieldPath.components(separatedBy:".")
            
            if !fieldNamePath.isEmpty {
                mainEntity = fieldNamePath.first!
            }
            if fieldNamePath.count == 2 || fieldNamePath.isEmpty {
                continue
            }else {
                let includeKeyArray = fieldNamePath.dropFirst().dropLast()
                var includeKeyString = ""
                
                for key in includeKeyArray {
                    if includeKeyString.isEmpty {
                        includeKeyString = key
                    }else {
                        includeKeyString = "\(includeKeyString).\(key)"
                    }
                }
                keyPath.append(includeKeyString)
            }
        }
        includeKeys = keyPath
    }
    
    private func prepareForFetchData() {
        
        if !fields.isEmpty {
            
            let filtered = fields.filter {(!($0 is ISParseBindable))}
            
            if !filtered.isEmpty {
                print("All fields must implement ISParseBindable protocol")
                return
            }else {
                buildIncludeKeys()
            }
        }else {
            return
        }
        
        if let data = self.parseObject {
            
            let query = PFQuery(className: data.parseClassName)
            query.cachePolicy = .networkElseCache
            
            query.includeKeys(self.includeKeys)
            
            query.getObjectInBackground(withId: data.objectId!, block: { (pObject, error) in
                
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                
                if let pObject = pObject {
                    
                    self.fetchedParseObject = pObject
                    
                    DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
                        // do some task
                        DispatchQueue.main.async {
                            self.fillFields()
                        }
                    }
                }
            })
            
        }
    }
    
    private func extractValueAndUpdateComponent(pfObject:PFObject,component:UIView) {
        
        var valueIsPFObject = false
        
        for key in pfObject.allKeys {
            valueIsPFObject = pfObject.value(forKey: key) is PFObject
            if valueIsPFObject {
                let filtered = nextObjectQueue.filter {($0.parseClassName == key.capitalizeFirst)}
                if filtered.isEmpty {
                    let ob = pfObject.value(forKey: key) as! PFObject
                    nextObjectQueue.append(ob)
                    extractValueAndUpdateComponent(pfObject:ob,component:component)
                }
                continue
            }
            if key == currentKeyPath.last {
                
                if let pfObject = pfObject.value(forKey: key) as? PFObject {
                    extractValueAndUpdateComponent(pfObject: pfObject, component: component)
                }else {
                    
                    if let textField = component as? UITextField {
                        var value = String(describing: pfObject.value(forKey: key)!)                        
                        let persistableComponent = (textField as! ISParseBindable)
                        
                        if persistableComponent.willFill != nil {
                            if let newValue = persistableComponent.willFill!(value: value) {
                                value = newValue as! String
                            }else {
                                return
                            }
                        }
                        
                        textField.text = value
                        persistableComponent.didFill?(value: value)
                    }else if let textView = component as? UITextView {
                        var value = String(describing: pfObject.value(forKey: key)!)
                        let persistableComponent = (textView as! ISParseBindable)
                        
                        if persistableComponent.willFill != nil {
                            if let newValue = persistableComponent.willFill!(value: value) {
                                value = newValue as! String
                            }else {
                                return
                            }
                        }

                        textView.text = value
                        persistableComponent.didFill?(value: value)
                    }else if let imageView = component as? UIImageView {
                        if var value = pfObject.value(forKey: key) as? PFFile {
                            let persistableComponent = (imageView as! ISParseBindable)
                            
                            if persistableComponent.willFill != nil {
                                if let newValue = persistableComponent.willFill!(value: value) {
                                    value = newValue as! PFFile
                                }else {
                                    return
                                }
                            }
                            
                            imageView.kf.setImage(with: URL(string:value.url!), placeholder: nil, options: nil, progressBlock: nil, completionHandler: { (image, error, cache, url) in
                                if let error = error {
                                    print(error.localizedDescription)
                                }
                                persistableComponent.didFill?(value: value)
                            })
                            
                        }
                    }else if let slider = component as? UISlider {
                        var value = pfObject.value(forKey: key)! as! Float
                        let persistableComponent = (slider as! ISParseBindable)
                        
                        if persistableComponent.willFill != nil {
                            if let newValue = persistableComponent.willFill!(value: value) {
                                value = newValue as! Float
                            }else {
                                return
                            }
                        }
                        
                        slider.value = value
                        persistableComponent.didFill?(value: value)
                    }else if let label = component as? UILabel {
                        var value = String(describing: pfObject.value(forKey: key)!)
                        let persistableComponent = (label as! ISParseBindable)
                        
                        if persistableComponent.willFill != nil {
                            if let newValue = persistableComponent.willFill!(value: value) {
                                value = newValue as! String
                            }else {
                                return
                            }
                        }
                        
                        label.text = value
                        persistableComponent.didFill?(value: value)
                    }
                    
                    return
                }
            }
        }
    }
    
    private func sortFields() {
        if isFieldSorted == true {
            return
        }
        
        let fieldsSortered = fields.sorted { (parseField1, parseField2) -> Bool in
            if parseField1 is ISParseBindable && parseField2 is ISParseBindable {
                return (parseField1 as! ISParseBindable).fieldPath.components(separatedBy: ".").count < (parseField2 as! ISParseBindable).fieldPath.components(separatedBy: ".").count
            }else {
                return false
            }
        }
        
        fields = fieldsSortered
        isFieldSorted = true
    }
    
    private func fillFields() {
        
        sortFields()
        if let fields = fields , !fields.isEmpty {
            for field in fields {
                if let field = field as? ISParseBindable, field is UIView {
                    
                    if  !(field.fieldPath.characters.count > 0) {
                        continue
                    }
                    
                    var keyPath = [String]()
                    var keyPathString = ""
                    for (index,path) in field.fieldPath.components(separatedBy: ".").enumerated() {
                        let path = path
                        if index == 0 {
                            continue
                        }
                        if index != field.fieldPath.components(separatedBy:".").count - 1 {
                            keyPathString = path
                        }
                        keyPath.append(path)
                    }
                    
                    //print(keyPath)
                    currentKeyPath = keyPath
                    
                    if nextObjectQueue.isEmpty {
                        nextObjectQueue.append(self.fetchedParseObject)
                    }
                    
                    if currentKeyPath.count == 1 {
                        extractValueAndUpdateComponent(pfObject:self.fetchedParseObject, component: (field as! UIView))
                    }else {
                        
                        let filtered = nextObjectQueue.filter {($0.parseClassName == keyPathString.capitalizeFirst)}
                        if filtered.isEmpty {
                            extractValueAndUpdateComponent(pfObject:self.fetchedParseObject, component: (field as! UIView))
                        }else {
                            extractValueAndUpdateComponent(pfObject:filtered.first!, component: (field as! UIView))
                        }
                    }
                }
            }
        }
    }
    
    private func buildFieldAndValues() {
        self.sortFields()
        
        for field in self.fields {
            
            let fieldPath = (field as! ISParseBindable).fieldPath
            let fieldType = ISParseBindFieldType(rawValue: (field as! ISParseBindable).fieldType)
            let isPersist = (field as! ISParseBindable).persist
            
            var fieldValue:AnyObject!
            
            guard isPersist == true else {
                continue
            }
            
            guard fieldPath.characters.count > 0 else {
                print("fieldPath is nil")
                continue
            }
            
            guard fieldType != nil else {
                print("fieldType is nil")
                continue
            }
            
            if let textField = field as? ISParseBindable , textField is UITextField
                && textField.fieldPath.characters.count > 0 {
                
                if ((textField as! UITextField).text!.characters.count) > 0 {
                    fieldValue = (textField as! UITextField).text! as AnyObject!
                }else {
                    fieldValue = "" as AnyObject
                }
                
            }else if let textView = field as? ISParseBindable, textView is UITextView
                && textView.fieldPath.characters.count > 0 {
                if ((textView as! UITextView).text!.characters.count) > 0 {
                    fieldValue = (textView as! UITextView).text! as AnyObject!
                }else {
                    fieldValue = "" as AnyObject
                }
                
            }else if let imageView = field as? ISParseBindable, imageView is UIImageView
                && imageView.fieldPath.characters.count > 0 {
                if (imageView as! UIImageView).image != nil {
                    fieldValue = (imageView as! UIImageView).image
                }else {
                    fieldValue = NSNull()
                }

            }else if let slider = field as? ISParseBindable, slider is UISlider
                && slider.fieldPath.characters.count > 0 {
                if (slider as! UISlider).value != -1 {
                    fieldValue = (slider as! UISlider).value as AnyObject!
                }else {
                    fieldValue = NSNull()
                }
                
            }else {
                print("\(fieldPath) is not compatible component, go to next...")
                continue
            }
            
            if let value = field.willSet?(value: fieldValue) {
                fieldValue = value as AnyObject!
            }
            
            fieldValue = self.getParseFieldValue(field:field, fieldValue: fieldValue, fieldType: fieldType!) as AnyObject!
            field.didSet?(value: fieldValue)
            
            self.fieldAndValues.append([fieldPath:fieldValue])
            
        }
    }
    
    open func save() {
        
        DispatchQueue.global(qos: .default).async(execute: {() -> Void in
            
            self.buildFieldAndValues()
            self.buildIncludeKeys()
            
            guard !self.fieldAndValues.isEmpty else {
                print("There is no persist fields for save")
                return
            }
            
            let parseEntityBuilder = ISParseBindEntityBuilder(with: self.fieldAndValues)
            
            print(ISParseBindEntityBuilder.mainDictionary)
            
            parseEntityBuilder.extractObjectsBeforeSave(mainEntity:self.mainEntity,includeKeys:self.includeKeys)
            
            var lastError:Error?
            var index = 0
            let total = parseEntityBuilder.dictionaryObjectsList.count
            var isLastObjectSave = false
            
            for dictionary in parseEntityBuilder.dictionaryObjectsList {
                
                let keyPath = dictionary.keys.first!
                let keyPathArray = keyPath.components(separatedBy: ".")
                
                let dictionaryObject = dictionary.values.first! as! [String:Any]
                
                var object = PFObject(className: keyPathArray.last!.capitalizeFirst, dictionary: dictionaryObject)
                
                do {
                    isLastObjectSave = (index == total - 1)
                    
                    if (index > 0) && !isLastObjectSave {
                        
                        //Check if there is last saved entity that need relation with current entity
                        let filtered = self.lastSavedObjectList.filter({ (dictionary: [String:PFObject]) -> Bool in
                            let keyPathArray = dictionary.keys.first!.components(separatedBy:".")
                            var keyPathString = ""
                            for (index,k) in keyPathArray.enumerated() {
                                if index == keyPathArray.count - 1 {
                                    continue
                                }
                                if keyPathString.isEmpty {
                                    keyPathString = "\(k)"
                                }else {
                                    keyPathString = "\(keyPathString).\(k)"
                                }
                            }
                            return keyPathString == keyPath
                        })
                        
                        if !filtered.isEmpty {
                            let savedObject = filtered.first!.values.first!
                            object[savedObject.parseClassName.uncapitalizeFirst] = savedObject
                        }
                        
                    }else if isLastObjectSave == true {
                        for keyAndPFObjects in self.lastSavedObjectList {
                            let pfObject = keyAndPFObjects.values.first!
                            if object[pfObject.parseClassName.uncapitalizeFirst] != nil {
                                object[pfObject.parseClassName.uncapitalizeFirst] = pfObject
                            }
                        }
                    }
                    
                    if let ob = self.delegate?.willSave(view: self, object: object) {
                        object = ob
                    }
                    
                    if !self.nextObjectQueue.isEmpty {
                        let filtered = self.nextObjectQueue.filter {($0.parseClassName == object.parseClassName)}
                        if !filtered.isEmpty {
                            object.objectId = filtered.first!.objectId
                        }
                    }
                    
                    try object.save()
                    if isLastObjectSave == true {
                        self.delegate?.allEntitiesDidSave(view: self, mainEntity: object, error: lastError)
                        self.lastSavedObjectList = []
                    }else {
                        self.delegate?.didSave(view: self, object: object, error: nil)
                        self.lastSavedObjectList.append([keyPath:object])
                    }
                    
                } catch {
                    lastError = error
                    self.delegate?.didSave(view: self, object: object, error: error)
                }
                
                index = index + 1
            }
            
        })
        
    }
}
