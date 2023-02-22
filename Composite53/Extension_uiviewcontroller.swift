//
//
//
//
//

import UIKit
//import iOS_Extension

//Declare enum
enum PushAnimationType{
    case animateFromRight
    case animateFromLeft
    case animateFromUp
    case animateFromDown
}

enum StoryBoardName: String {
    case mainSB = "Main"
}


extension UIViewController {
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func popTo<T>(withScreen vcType : T) {
        for controller in self.navigationController!.viewControllers as Array {
            if let className = vcType.self as? AnyClass {
                if controller.isKind(of: className ) {
                    self.navigationController!.popToViewController(controller, animated: true)
                    break
                }
            }
        }
    }
    
    
//    func popToPerticularVC <T>(withVC popVC : T) {
//        let viewControllers: [UIViewController] = self.navigationController!.viewControllers
//        for objVC in viewControllers {
//            if objVC == popVC {
//                self.navigationController!.popToViewController(objVC, animated: true)
//                break
//            }
//
//        }
//
//    }
    
    
    func popToVC(withVC popVC: AnyClass){
        
        for controller in self.navigationController!.viewControllers as Array {
                if controller.isKind(of: popVC.self) {
                    _ =  self.navigationController!.popToViewController(controller, animated: true)
                    break
                }
            }
    }
//   MARK:- Load Controller
    class func loadViewController(withStoryBoard storyBoardName: StoryBoardName) -> Self {
        return instantiateViewController(withStoryBoard: storyBoardName.rawValue)
    }
    
    private class func instantiateViewController<T>(withStoryBoard storyBoardName: String) -> T{
        let sb: UIStoryboard = UIStoryboard(name: storyBoardName, bundle: nil)
        let controller  = sb.instantiateViewController(withIdentifier: String(describing: self)) as! T
        return controller
    }

    //MARK:- changeRootViewControllerWithPushanimation
    func showViewControllerWith(newViewController:UIViewController, usingAnimation animationType:PushAnimationType)
    {
        if let currentViewController = UIApplication.shared.delegate?.window??.rootViewController {
            let width = currentViewController.view.frame.size.width;
            let height = currentViewController.view.frame.size.height;
            
            var previousFrame: CGRect?
            var nextFrame: CGRect?
            
            switch animationType
            {
            case .animateFromLeft:
                previousFrame = CGRect(x: width - 1, y: 0.0, width: width, height: height)
                nextFrame = CGRect(x: -width * 0.3, y: 0.0, width: width, height: height)
            case .animateFromRight:
                previousFrame = CGRect(x: -width + 1, y: 0.0, width: width, height: height)
                nextFrame = CGRect(x: width * 0.3, y: 0.0, width: width, height: height)
            case .animateFromUp:
                previousFrame = CGRect(x: 0.0, y: height - 1.0, width: width, height: height)
                nextFrame = CGRect(x: 0.0, y: -height + 1, width: width, height: height)
            case .animateFromDown:
                previousFrame = CGRect(x: 0.0, y: -height + 1.0, width: width, height: height)
                nextFrame = CGRect(x: 0.0, y: height - 1, width: width, height: height)
            }
            
            newViewController.view.frame = previousFrame!
            UIApplication.shared.delegate?.window??.addSubview(newViewController.view)
            UIView.animate(withDuration: 0.33, animations: {
                newViewController.view.frame = currentViewController.view.frame
                currentViewController.view.frame = nextFrame!
            }, completion: { (fihish) in
                UIApplication.shared.delegate?.window??.rootViewController = newViewController
            })
        }
    }
    
    //MARK:- get TopViewController
    static public var topMostController: UIViewController {
        if let topVC = UIViewController.topViewController() {
            return topVC
        }
        else if let window =  UIApplication.shared.delegate!.window, let rootVC = window?.rootViewController {
            return rootVC
        }
        return UIViewController()
    }
    
    //private class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
    private class func topViewController(controller: UIViewController? = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController) -> UIViewController? {
        
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        
        if let vC = controller, let childVC = vC.children.first as? UIPageViewController, let curruntVC = childVC.viewControllers?.first {
            return curruntVC
        }
        
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
extension UIView {
    func rotate360Degrees(duration: CFTimeInterval = 1.0, completionDelegate: AnyObject? = nil) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(Double.pi)
        rotateAnimation.duration = duration
        
        if let delegate: CAAnimationDelegate = completionDelegate as! CAAnimationDelegate? {
            rotateAnimation.delegate = delegate
        }
        self.layer.add(rotateAnimation, forKey: nil)
    }
    
    func rotateAnimation (duration: CFTimeInterval = 3) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(Double.pi * 2)
        rotateAnimation.isRemovedOnCompletion = false
        rotateAnimation.duration = duration
        rotateAnimation.repeatCount=Float.infinity
        self.layer.add(rotateAnimation, forKey: nil)
    }
}
extension UIView {
    private static let kRotationAnimationKey = "rotationanimationkey"
    
    func rotate(duration: Double = 1) {
        if layer.animation(forKey: UIView.kRotationAnimationKey) == nil {
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
            
            rotationAnimation.fromValue = 0.0
            rotationAnimation.toValue = Float.pi * 2.0
            rotationAnimation.duration = duration
            rotationAnimation.repeatCount = Float.infinity
            
            layer.add(rotationAnimation, forKey: UIView.kRotationAnimationKey)
        }
    }
    
    func stopRotating() {
        if layer.animation(forKey: UIView.kRotationAnimationKey) != nil {
            layer.removeAnimation(forKey: UIView.kRotationAnimationKey)
        }
    }
}


extension UINavigationController {
    
    func backToPerticularVC(vc: Any) {
        // iterate to find the type of vc
        for element in viewControllers as Array {
            if "\(type(of: element)).Type" == "\(type(of: vc))" {
                self.popToViewController(element, animated: true)
                break
            }
        }
    }
    
}
extension UIApplication {
    var statusBarUIViewTZ: UIView? {
        if #available(iOS 13.0, *) {
            let tag = 3848
            if let statusBar = self.keyWindow?.viewWithTag(tag) {
                return statusBar
            } else {
                let statusBarView = UIView(frame: UIApplication.shared.statusBarFrame)
                statusBarView.tag = tag

                self.keyWindow?.addSubview(statusBarView)
                return statusBarView
            }
        } else {
            if let statusBar = (UIApplication.shared.value(forKey: "statusBarWindow") as AnyObject).value(forKey: "statusBar") as? UIView {
                return statusBar
            }
        }
        return nil
    }
}

extension UINavigationBar {
    
    func setGradientBackground(colors: [UIColor]) {
        /*
        var updatedFrame = bounds
        updatedFrame.size.height += self.frame.origin.y
        let gradientLayer = CAGradientLayer(frame: updatedFrame, colors: colors)
       // gradientLayer.name = "gradient2"
        self.roundCorners([.topLeft,.topRight], radius: 40.0)
        //gradientLayer.roun cornerRadius = 15
        
        gradientLayer.backgroundColor = UIColor.red.cgColor
        self.clipsToBounds = false
        */
        
        var updatedFrame = bounds
        updatedFrame.size.height += self.frame.origin.y
        let gradientLayer = CAGradientLayer(frame: updatedFrame, colors: colors)
        
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
        setBackgroundImage(gradientLayer.createGradientImage(), for: UIBarMetrics.default)
    }
}


extension CAGradientLayer {
    
    convenience init(frame: CGRect, colors: [UIColor]) {
        self.init()
        self.frame = frame
        self.colors = []
        for color in colors {
            self.colors?.append(color.cgColor)
        }
        startPoint = CGPoint(x: 0, y: 1)
        endPoint = CGPoint(x: 1, y: 1)
    }
    
    func createGradientImage() -> UIImage? {
        
        var image: UIImage? = nil
        UIGraphicsBeginImageContext(bounds.size)
        if let context = UIGraphicsGetCurrentContext() {
            render(in: context)
            image = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        return image
    }
    
}
