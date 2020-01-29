//
//  ViewControllerExt.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 07/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    func showOkAlert(title: Words, msg: Words) {
        showOkAlert(title: title.localized, msg: msg.localized)
    }
    
    func showOkAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func showAlertWithTextField(
        title: String,
        placeholder: String,
        leftButtonTitle: String,
        rightButtonTitle: String,
        rightActionEnabled: Bool = true,
        textFieldDelegate: UITextFieldDelegate? = nil,
        //leftBlock: ((UIAlertAction) -> Void)? = nil,
        //rightBlock: ((UIAlertAction) -> Void)? = nil) {
        rightBlock: ((String?) -> Void)? = nil) -> UIAlertController {
        
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let leftAction = UIAlertAction(title: leftButtonTitle, style: .cancel) { (_) in }
        let rightAction = UIAlertAction(title: rightButtonTitle, style: .default) { (_) in
            let text = alert.textFields?.first?.text
            rightBlock?(text)
        }
        
        rightAction.isEnabled = rightActionEnabled
        
        alert.addTextField { (textField) in
            textField.placeholder = placeholder
            textField.delegate = textFieldDelegate
        }
        
        alert.addAction(rightAction)
        alert.addAction(leftAction)
        
        self.present(alert, animated: true, completion: nil)
        
        return alert
    }
    
    func showAlertWithTextView(
        title: String,
        placeholder: String,
        leftButtonTitle: String,
        rightButtonTitle: String,
        initialText: String? = "",
        rightActionEnabled: Bool = true,
        textViewDelegate: UITextViewDelegate? = nil,
        //leftBlock: ((UIAlertAction) -> Void)? = nil,
        //rightBlock: ((UIAlertAction) -> Void)? = nil) {
        rightBlock: ((String?) -> Void)? = nil) -> UIAlertController {
        
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)

        let textView = UITextView()
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textView.font = UIFont.systemFont(ofSize: 14.0)
        textView.text = initialText
        textView.delegate = textViewDelegate
        
        let controller = UIViewController()
        textView.frame = controller.view.frame
        controller.view.addSubview(textView)
        
        let leftAction = UIAlertAction(title: leftButtonTitle, style: .cancel) { (_) in }
        let rightAction = UIAlertAction(title: rightButtonTitle, style: .default) { (_) in
            rightBlock?(textView.text)
        }
        
        rightAction.isEnabled = rightActionEnabled
        alert.addAction(rightAction)
        alert.addAction(leftAction)
        alert.setValue(controller, forKey: "contentViewController")
        
        let height: NSLayoutConstraint = NSLayoutConstraint(item: alert.view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: view.frame.height * 0.5)
        alert.view.addConstraint(height)
        
        present(alert, animated: true, completion: { textView.becomeFirstResponder() })
        return alert
    }
    
    func showDatePicker(
        mode: UIDatePicker.Mode,
        title: String,
        leftButtonTitle: String,
        rightButtonTitle: String,
        rightBlock: ((Date) -> Void)? = nil) -> UIAlertController {
        
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        let picker = UIDatePicker(frame: CGRect.zero)
        picker.datePickerMode = mode
        picker.minimumDate = Date()
        
        let controller = UIViewController()
        controller.view.addSubview(picker)
        picker.fillToSuperview()
        
        let leftAction = UIAlertAction(title: leftButtonTitle, style: .cancel) { (_) in }
        let rightAction = UIAlertAction(title: rightButtonTitle, style: .default) { (_) in
            rightBlock?(picker.date)
        }
        
        alert.addAction(rightAction)
        alert.addAction(leftAction)
        alert.setValue(controller, forKey: "contentViewController")
        
        present(alert, animated: true, completion: nil)
        return alert
    }
    
    func createViewController(withInfo info: ViewControllerInfo) -> UIViewController {
        let storyboard = UIStoryboard(name: info.storyboard.rawValue, bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: info.name)
        return controller
    }
    
    func showViewController(withInfo info: ViewControllerInfo, withPush push: Bool = true) {
        if self is UINavigationController {
            print2("Panic!!! Do not call showViewController with UINavigationController")
            return
        }
        
        let vc = createViewController(withInfo: info)
        if push {
            navigationController?.pushViewController(vc, animated: true)
        } else {
            navigationController?.setViewControllers([vc], animated: true)
        }
    }
    
    func makeNavigationBarTransparent() {
        if let nb = navigationController?.navigationBar {
            nb.setBackgroundImage(UIImage(), for: .default)
            nb.shadowImage = UIImage()
            nb.backgroundColor = UIColor.clear
            nb.isTranslucent = true
        }
    }
    
    func eraseBackButtonTitle() {
        navigationController?.navigationBar.topItem?.title = " "
    }
    
    func createViewFromNib(nibName: String) -> UIView? {
        guard let view = Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)?.last as? UIView else { return nil }
        return view
    }
    
    func topViewController() -> UIViewController {
        if let presented = self.presentedViewController {
            return presented.topViewController()
        }
        
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topViewController() ?? navigation
        }
        
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topViewController() ?? tab
        }
        
        return self
    }
}
