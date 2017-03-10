//
//  ISParseBindView.swift
//  Pods
//
//  Created by Daniel Amaral on 27/01/17.
//
//

import UIKit
import Parse

public protocol ISParseBindViewDelegate {
    func willSave(view:ISParseBindView,object:PFObject) -> PFObject?
    func didSave(view:ISParseBindView,object:PFObject,error:Error?)
    func allEntitiesDidSave(view:ISParseBindView,mainEntity:PFObject,error:Error?)
}

open class ISParseBindView: UIView {
    
    @IBOutlet open var fields:[AnyObject]!
    
    //fieldAndValues store fieldNames fieldValues of ISPersistable fields
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
    
    private func getParseFieldValue(fieldValue:AnyObject,fieldType:ISParseFieldType) -> Any {
        
        var fieldValue = fieldValue
        
        if !(fieldValue is NSNull) {
            switch fieldType {
            case .Number:
                if let stringValue = fieldValue as? String {
                    fieldValue = stringValue.replacingOccurrences(of: ",", with: ".") as AnyObject
                }
                fieldValue = fieldValue.doubleValue as AnyObject
                return fieldValue
                break
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
                break
            case .Array:
                fieldValue = [getFieldWithCast(fieldValue)] as [Any] as AnyObject
                return fieldValue
                break
            default:
                return fieldValue
                break
            }
        }
        return ""
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
            let fieldNamePath = (field as! ISPersistable).fieldName.components(separatedBy:".")
            
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
            
            let filtered = fields.filter {(!($0 is ISPersistable))}
            
            if !filtered.isEmpty {
                print("All fields must implement ISPersistable protocol")
                return
            }else {
                buildIncludeKeys()
            }
        }else {
            return
        }
        
        if let data = self.parseObject {
            
            let query = PFQuery(className: data.parseClassName)
            query.getDataFromLocalStoreElseSetupCachePolicy(cachePolicy: .networkElseCache)
            
            query.includeKeys(self.includeKeys)
            
            query.getObjectInBackground(withId: data.objectId!, block: { (pObject, error) in
                
                if error != nil {
                    print(error)
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
    
    private func extractValueAndUpdateComponent(pfObject:PFObject,textField:UITextField) {
        
        var valueIsPFObject = false
        
        for key in pfObject.allKeys {
            valueIsPFObject = pfObject.value(forKey: key) is PFObject
            if valueIsPFObject {
                let filtered = nextObjectQueue.filter {($0.parseClassName == key.capitalizeFirst)}
                if filtered.isEmpty {
                    let ob = pfObject.value(forKey: key) as! PFObject
                    nextObjectQueue.append(ob)
                    extractValueAndUpdateComponent(pfObject:ob,textField:textField)
                }
                continue
            }
            if key == currentKeyPath.last {
                
                if let pfObject = pfObject.value(forKey: key) as? PFObject {
                    extractValueAndUpdateComponent(pfObject: pfObject, textField: textField)
                }else {
                    //print("\(pfObject.value(forKey: key))")
                    textField.text = String(describing: pfObject.value(forKey: key)!)
                    return
                }
            }
        }
    }
    
    private func sortFields() {
        if isFieldSorted == true {
            return
        }
        
        let fieldsSortered = fields.sorted { (parseTextField1, parseTextField2) -> Bool in
            if parseTextField1 is ISParseTextField && parseTextField2 is ISParseTextField {
                return (parseTextField1 as! ISParseTextField).fieldName.components(separatedBy: ".").count < (parseTextField2 as! ISParseTextField).fieldName.components(separatedBy: ".").count
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
                if let textField = field as? ISPersistable , textField is UITextField {
                    
                    if  !(textField.fieldName.characters.count > 0) {
                        continue
                    }
                    
                    var keyPath = [String]()
                    var keyPathString = ""
                    for (index,path) in textField.fieldName.components(separatedBy: ".").enumerated() {
                        var path = path
                        if index == 0 {
                            continue
                        }
                        if index != textField.fieldName.components(separatedBy:".").count - 1 {
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
                        extractValueAndUpdateComponent(pfObject:self.fetchedParseObject, textField: textField as! UITextField)
                    }else {
                        
                        let filtered = nextObjectQueue.filter {($0.parseClassName == keyPathString.capitalizeFirst)}
                        if filtered.isEmpty {
                            extractValueAndUpdateComponent(pfObject:self.fetchedParseObject, textField: textField as! UITextField)
                        }else {
                            extractValueAndUpdateComponent(pfObject:filtered.first!, textField: textField as! UITextField)
                        }
                    }
                }
            }
        }
    }
    
    private func buildFieldAndValues() {
        self.sortFields()
        
        for field in self.fields {
            var fieldPath:String!
            var fieldValue:Any!
            var fieldType:ISParseFieldType!
            
            if let textField = field as? ISPersistable , textField is UITextField
                && textField.fieldName.characters.count > 0 {
                
                if ((textField as! UITextField).text!.characters.count) > 0 {
                    fieldValue = (textField as! UITextField).text as AnyObject!
                }else {
                    fieldValue = NSNull()
                }
                
                fieldType = ISParseFieldType(rawValue: textField.fieldType)
                
                if fieldType == nil {
                    print("fieldType \(fieldType) is not valid")
                    return
                }
            }else if let textView = field as? ISPersistable, textView is UITextView
                && textView.fieldName.characters.count > 0 {
                if ((textView as! UITextView).text!.characters.count) > 0 {
                    fieldValue = (textView as! UITextView).text as AnyObject!
                }else {
                    fieldValue = NSNull()
                }
                
                fieldType = ISParseFieldType(rawValue: textView.fieldType)
                
                if fieldType == nil {
                    print("fieldType \(fieldType) is not valid")
                    return
                }
            }else if let imageView = field as? ISPersistable {
                
            }else {
                print("Some field is not compatible, go to next...")
                continue
            }
            
            fieldValue = self.getParseFieldValue(fieldValue: fieldValue as AnyObject, fieldType: fieldType)
            fieldPath = (field as! ISPersistable).fieldName
            self.fieldAndValues.append([fieldPath:fieldValue])
            
        }
    }
    
    open func save() {
        
        DispatchQueue.global(qos: .default).async(execute: {() -> Void in
            
            self.buildFieldAndValues()
            self.buildIncludeKeys()
            
            let parseEntityBuilder = ISParseEntityBuilder(with: self.fieldAndValues)
            
            print(ISParseEntityBuilder.mainDictionary)
            
            parseEntityBuilder.extractObjectsBeforeSave(mainEntity:self.mainEntity,includeKeys:self.includeKeys)
            
            var lastError:Error?
            var index = 0
            var total = parseEntityBuilder.dictionaryObjectsList.count
            var isLastObjectSave = false
            
            for dictionary in parseEntityBuilder.dictionaryObjectsList as! [[String:Any]] {
                
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
