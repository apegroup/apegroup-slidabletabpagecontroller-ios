# APSlidableTabPageController

## Description:
- A slidable tab page controller written in Swift. 
- Supports both Portrait and Landscape.

![slidabletabpagecontroller](https://cloud.githubusercontent.com/assets/16682908/12745471/ac8c307e-c999-11e5-83e1-455f949cc4d6.gif)

## Installation:
- Fetch with Carthage, e.g:
  - 'github "apegroup/APSlidableTabPageController-iOS"'

## Usage:
```swift
  import APSlidableTabPageController
  
  let arrayOfViewControllers: [UIViewController] = ...
  
  //Create
  let tabPageCtrl = APSlidableTabPageControllerFactory.make(childViewControllers: arrayOfViewControllers)
  
  //Configure appearance
  tabPageCtrl.indexBarTextColor = UIColor.black()
  tabPageCtrl.indexBarHighlightedTextColor = UIColor.white()
  ```

## Restrictions:
- Must be instantiated from a NIB

## Known Issues:

Feel free to contribute!
