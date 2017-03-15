# ISParseBind

With ISParseBind you can save, update and query PFObjects using the power of Xcode Interface Builder resources.

![ISParseBind Video](https://img.youtube.com/vi/WCZRNC_mHNQ/0.jpg)

​						https://www.youtube.com/watch?v=WCZRNC_mHNQ

### Supported Components:
- UITextField
- TextView
- UIImageView
- UISlider
- UILabel (Read Only)
- UIButton (Comming soon for Radio Button)

### Custom Components:
- You can implement ISParseBindable protocol to create your own component.
- All custom components need to subclass one of the supported components and to implement ISParseBindable

### Requirements:
- iOS 9 +
- Swift 3

### Install with Cocoapods:
- pod 'ISParseBind', :git => 'https://github.com/ilhasoft/ISParseBind.git', :branch => 'master'

### How does it work? Interface Builder Step
- Add a UIView in your xib/story board and set that as ISParseBindView subclass.
- Add some components that implement ISParseBindable in that ISParseBindView.
- On the Attributes Inspector, fill: FieldType, FieldPath and Persist - the others aren't required.
- After setting up the components, you need right click on your ISParseBindView and bind it with ISParseBindable components.
- Create an @IBoutlet to bind your ISParseBindView.

### How does it work in practice? Code Step

Setup Parse Server credentials in AppDelegate, on "didFinishLaunchingWithOptions" method:

```swift
    let parseConfiguration = ParseClientConfiguration(block: { (ParseMutableClientConfiguration) -> Void in
        ParseMutableClientConfiguration.applicationId = "applicationID"
        ParseMutableClientConfiguration.clientKey = "clientKey"
        ParseMutableClientConfiguration.server = "serverURL"
    })
    
    Parse.initialize(with: parseConfiguration)
```

In some UIViewController, do:

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
    
  func didSave(view: ISParseBindView, object: PFObject, isMainEntity:Bool, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            DispatchQueue.main.async {
                self.hud?.hide(animated: true)
            }
        }else {
            if isMainEntity == true {
                self.parseBindView.parseObject = object
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
| Required Error   | String (optional)                        | Error message if component is not filled |
| Field Type       | String: 'Text', 'Number', 'Logic' or 'Image' | This is necessary for the algorithm to cast correctly for the corresponding field type in Parse. |
| Filed Type Error | String (optional)                        | Cast error message                       |
| Field Path       | String                                   | Path of the field on your class structure, for example: 'vehicle.brand.car.model'. Vehicule will be your main entity, 'Brand' and 'Car' will be relations class that will be created automatically, and 'model' will be the field of 'Car' Class. |
| Persist          | Bool                                     | If persist = false then this field will only use "read only" mode. |



> Developers can use optionals ISParseBindable vars to create your own field validator.
>
> FieldTypeError, Required and Required Error is not used in ISParseBind algorithm. You can use as Helper to make your own validation rule.



### Class Structure 

- Sample of Input in Field Path: "vehicle.brand.car.model", will generate this class structure:

  ```markdown
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

  - "model" value depends of its component's type. For example, if the component is a UITextField or a UITextView, the value will be a String. If the component is a UIImageView, however, the value will be a UIImage that will be cast to a PFFile in the algorithm.
  - In the above dictionary structure, the algorithm will generate 3 classes in the Parse Server: Vehicule, Brand and Car.
  - The last string after "." in the fieldPath will always be the field in Parse Server. 'model', in the given example, will be a field and not a class.



### Be alerted, before and after, of set or filling the value of a component

For that you need implement some ISParseBind Component, such as:

  - ISParseBindImageView, ISParseBindTextField, ISParseBindTextView, ISParseBindSlider, ISParseBindLabel.

Or you can create your own component that implements ISParseBindable and supports native components of the section 'Supported Components'. You will also need to implement these functions:

    ```swift
    func willSet(value:Any) -> Any?
    func didSet(value:Any)
    func willFill(value:Any) -> Any?
    func didFill(value:Any)
    ```

    > willFill can be used for "string format" for example before fill the field.
    >
    > willSet can be used for remove the string formatation before save in Parse. 
    >
    > You can ignore willFill returning "nil" on willFill implementation method
    >
    > You can set persist = false in execution time, you only need implement willSet and call self.persist = false before the method return.
