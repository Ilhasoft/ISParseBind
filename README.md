# ISParseBind

With ISParseBind you can save, update and query PFObjects using the power of Xcode Interface Builder resources.

![ISParseBind Video](https://img.youtube.com/vi/WCZRNC_mHNQ/0.jpg)

​						https://www.youtube.com/watch?v=WCZRNC_mHNQ

### Supported Components:
- UITextField
- TextView
- UIImageView
- UISlider
- UISwitch
- UILabel (Read Only)
- UIButton (Comming soon for Radio Button)



### Custom Components:

- You can implement ISParseBindable protocol to create your own component.
- All custom components need to subclass one of the supported components and to implement ISParseBindable



### Requirements:

- iOS 9 +
- Swift 3



### Install with Cocoapods:

- pod 'ISParseBind'



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

1:

```swift
import ISParseBind
```
2:

```swift
@IBOutlet var parseBindView:ISParseBindView!
```
3: Implement ISParseBindViewDelegate.
>It's not mandatory, but if you need to intercept some methods of before or after processing, implement:

```swift
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
        
  }
  
  
  func willFill(component: Any, value: Any) -> Any? {
      //Check wich component will be filled and return a custom value
      if let component = component as? UITextField, component == txtName {
          return "\(value as! String) Smith"

      //Return nil if you want to ignore the fill
      }else if let component = component as? UIImageView, component == imgPicture {
          return nil
      }

      return value
   }
    
  func didFill(component: Any, value: Any) { }

  func willSet(component: Any, value: Any) -> Any? {
      //Check wich component will be setup and return a custom value
      if let component = component as? UIImageView, component == imgPicture {
          return getImageInGrayScale(imgPicture.image)
      }        
      return value
  }

  func didSet(component: Any, value: Any) { }  
}
```
4: 

```swift
self.parseBindView.save()
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

