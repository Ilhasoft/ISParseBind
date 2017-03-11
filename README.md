# ISParseBind

With ISParseBind you can save, update, and query PFObjects using the power of Xcode Interface Builder resources.

### Supported Components:
- UITextField
- TextView
- UIImageView
- UISlider
- UILabel (Read Only)
- UIButton (Comming soon for Radio Button)

### Custom Components:
- You can implement ISParseBindable protocol for create your own component.
- Custom components need subclass Supported Components and implement ISParseBindable

### Requirements:
- iOS 9 +
- Swift 3

### Install with Cocoapods:
- pod 'ISParseBind', :git => 'https://github.com/ilhasoft/ISParseBind.git', :branch => 'master'

### How it works? Interface Builder Step
- Add UIView in your xib/story board and set that as ISParseBindView subclass.
- Add some components that implement ISParseBindable in that ISParseBindView.
- On Attributes Inspector, fill: FieldType, FieldPath and Persist, the others aren't required.
- After setup the components, you need right click on your ISParseBindView and bind it with ISParseBindable components.
- Create an @IBoutlet for bind your ISParseBindView.

### How it works in practice? Code Step

```swift
1: import ISParseBind
```
```swift
2: @IBOutlet var parseBindView:ISParseBindView!
```
```swift
3: Implement ISParseBindViewDelegate

parseBindView.delegate = self

extension yourViewController : ISParseBindViewDelegate {
  func willSave(view: ISParseBindView, object: PFObject) -> PFObject? {
        //If you need, you can intercept the current PFObject that will be saved and change some attributes before that. For example:
        //if object.parseClassName == "Car" {
        //    object["color"] = "Yellow"
        //}
        return object
    }
    
    func didSave(view: ISParseBindView, object: PFObject, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        	DispatchQueue.main.async {
            	MBProgressHUD.hide(for: self.view, animated: true)
        	}
        }else {
            print("didSave \(object.parseClassName)")
        }
    }
    
    func allEntitiesDidSave(view: ISParseBindView, mainEntity: PFObject, error: Error?) {
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
        self.parseBindView.parseObject = mainEntity // If you put this line, ISParseBind will update all objects in next save() call        
        if let error = error {
            print(error.localizedDescription)
        }else {
            print("allEntitiesDidSave")
        }
    }
}
```
```swift
4: self.parseBindView.save()
```


### ISParseBindable vars

Learn about how to use variables of ISParseBindable protocol works.

| Variable         | Type                                     | Description                              |
| ---------------- | ---------------------------------------- | ---------------------------------------- |
| Required         | Bool (optional)                          | Fill component is mandatory              |
| Required Error   | String (optional)                        | Error message is component is not filled |
| Field Type       | String: 'Text', 'Number', 'Logic' or 'Image' | This is necessary for the algorithm to cast correctly for the corresponding field type in Parse. |
| Filed Type Error | String (optional)                        | Cast error message                       |
| Field Path       | String                                   | Path of the field on your class structure, for example: 'vehicle.brand.car.model'. Vehicule will be your main entity, 'Brand' and 'Car' will be relations class that will be created automatically, and 'model' will be the field of 'Car' Class. |
| Persist          | Bool                                     | If persist = false then this field will only use "read only" mode. |



> Developers can use optionals ISParseBindable vars for create your own field validator.



### Class Structure 

- Sample of Input in Field Path: "vehicle.brand.car.model", will generate this class structure:

  ```json
  {
      vehicle = {
          brand = {
           	 car = {
              	model: 
            	 }
          }
      }
  }
  ```

  - "model" value depends of component, for example, if component is a UITextField or UITextView the value will be a String but if component is UIImageView, the value will be UIImage that will be cast to PFFile in algorithm.
    ​
  - In that dictionary structure above, the algorithm will generate 3 classes in Parse Server: Vehicule, Brand and Car.
  - Ever, the last string after "." in fieldPath will be the field in Parse Server, 'model' in that case will be a field and not a class.



### Be alerted, before and after, of set or filling the value of component

- For that you need implement some ISParseBind Component, like:

  - ISParseBindImageView, ISParseBindTextField, ISParseBindTextView, ISParseBindSlider, ISParseBindLabel.

  - Or you can create your own component that implement ISParseBindable and  support native components of section Supported Components, and implement these functions:

    ```swift
        @objc optional func willSet(value:Any) -> Any?
        @objc optional func didSet(value:Any)
        @objc optional func willFill(value:Any) -> Any?
        @objc optional func didFill(value:Any)
    ```

    > willFill can be used for "string format" for example before fill the field.
    >
    > willSet can be used for remove the string formatation before save in Parse. 



### GIF Sample

- Comming soon.



