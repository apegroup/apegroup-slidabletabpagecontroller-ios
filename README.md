# APSlidableTabPageController

## Description:
- A slidable tab page controller written in Swift
- Supports both Portrait and Landscape
- Configurable:
  - index bar position (top or bottom)
  - index bar height
  - number of index bar elements per page
  - index bar element image or text
  - coloring

![slidabletabpagecontroller](https://cloud.githubusercontent.com/assets/653946/17456681/0861e190-5be0-11e6-971f-f61cf152b3b3.gif)

## Installation:
- Fetch with Carthage, e.g:
- 'github "apegroup/APSlidableTabPageController-iOS"'

## Usage example:
```swift
import APSlidableTabPageController

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
      let tabPageCtrl = APSlidableTabPageControllerFactory.make(childViewControllers: createViewControllers(count: 7))
      tabPageCtrl.indexBarPosition = .bottom
      tabPageCtrl.maxNumberOfIndexBarElementsPerScreen = 4.5
      tabPageCtrl.indexBarHeightConstraint.constant = 49
      tabPageCtrl.indexBarElementColor = UIColor.black
      tabPageCtrl.indexBarElementHighlightedColor = tabPageCtrl.indexIndicatorView.backgroundColor!

      window = UIWindow()
      window?.rootViewController = tabPageCtrl
      window?.makeKeyAndVisible()
      return true
    }

  private func createViewControllers(count: Int) -> [UIViewController] {
    return (0..<count).map { i -> UIViewController in
      let vc = UIViewController()
      vc.title = "\(i)"
      vc.view.backgroundColor = randomColor()

      if i == 0 {
        vc.tabBarItem.image = UIImage(named: "icon-star")?.withRenderingMode(.alwaysTemplate)
        vc.tabBarItem.selectedImage = UIImage(named: "icon-plane")?.withRenderingMode(.alwaysTemplate)
      } else if i == 1 {
          vc.title = "hello there"
      } else if i == 2 {
          vc.tabBarItem.image = UIImage(named: "icon-star")
      } else if i == 4 {
          vc.title = "a veeeery long (truncated) title"
      }
      return vc
    }
  }

  private func randomColor() -> UIColor {
    return UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1)
  }
}
  ```

## Restrictions:
- Must be instantiated from a NIB

## Known Issues:

Feel free to contribute!
