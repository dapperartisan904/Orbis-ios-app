//
//  BaseAuthViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 22/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import FirebaseAuth
import FBSDKLoginKit
import TwitterKit
import MKProgress

enum AuthSource {
    case email, fb
}

class BaseAuthViewController : OrbisViewController {
    
    @IBOutlet weak var toolbar: BaseToolbar!
    @IBOutlet weak var usernameField: FormTextField!
    @IBOutlet weak var pwdField: FormTextField!
    @IBOutlet weak var orLabel: UILabel!
    @IBOutlet weak var fbImageView: UIImageView!
    @IBOutlet weak var twitterImageView: UIImageView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var termsLabel: UILabel!
    
    let viewModel = RegisterViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbar.delegate = self
        
        if #available(iOS 11.0, *) {
            usernameField.textField.textContentType = UITextContentType.username
        }

        usernameField.textField.autocapitalizationType = UITextAutocapitalizationType.none
        usernameField.setText(text: nil, placeholder: Words.username.localized)
        
        pwdField.asPwd()
        pwdField.setText(text: nil, placeholder: Words.password.localized)

        orLabel.text = Words.or.localized
        termsLabel.text = Words.termsOfService.localized
        
        termsLabel.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { _ in
                UIApplication.shared.open(tosPage, options: [:])
            })
            .disposed(by: bag)
        
        fbImageView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.showTermsOfUserAlert(source: .fb)
            })
            .disposed(by: bag)
        
        // TODO KINE: twitter disabled for now
        let twitterEnabled = false
        
        if twitterEnabled {
            twitterImageView.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    self?.twitterLogin()
                })
                .disposed(by: bag)
        }
        else {
            twitterImageView.isHidden = true
            stackView.removeArrangedSubview(twitterImageView)
        }
        
        observeDefaultSubject(subject: viewModel.subject)
    }
    
    override func shouldObserveActiveGroup() -> Bool {
        return false
    }
    
    override func onTaskStarted() {
        MKProgress.show()
    }
    
    override func onTaskFailed() {
        MKProgress.hide()
    }
    
    override func onTaskFinished() {
        MKProgress.hide()
        navigationController?.popToRootViewController(animated: true)
    }
    
    private func fbLogin() {
        onTaskStarted()
        
        let manager = LoginManager()
        manager.logIn(permissions: ["public_profile"], from: self) { [weak self] (result: LoginManagerLoginResult?, error: Error?) in
            if let error = error {
                print2("Facebook login error [1]")
                print2(error)
                self?.showOkAlert(title: Words.error.localized, msg: Words.errorGeneric.localized)
                self?.onTaskFailed()
                return
            }
            
            guard let result = result else {
                self?.onTaskFailed()
                self?.showOkAlert(title: Words.error.localized, msg: Words.errorGeneric.localized)
                return
            }
            
            print2("Faceboook login is canceled: \(result.isCancelled)")
            
            if result.isCancelled {
                self?.onTaskFailed()
                return
            }
            
            guard let token = AccessToken.current?.tokenString else {
                self?.onTaskFailed()
                self?.showOkAlert(title: Words.error.localized, msg: Words.errorGeneric.localized)
                return
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            self?.viewModel.loginWithProvider(credential: credential)
        }
    }
    
    /*
        O TwitterKit está deprecated e parece bugado
        https://blog.twitter.com/developer/en_us/topics/tools/2018/discontinuing-support-for-twitter-kit-sdk.html
        https://groups.google.com/forum/?nomobile=true#!topic/firebase-talk/KeqfIqZmBag
     
        Talvez uma alternativa seria fazer o login via REST
        https://github.com/OAuthSwift/OAuthSwift
        https://developer.twitter.com/en/docs/twitter-for-websites/log-in-with-twitter/guides/implementing-sign-in-with-twitter
     */
    private func twitterLogin() {
        onTaskStarted()
        
        print2("Twitter login started")
        
        TWTRTwitter.sharedInstance().logIn { [weak self] (session: TWTRSession?, error: Error?) in
            if let error = error {
                print2("Twitter login error [1]")
                print2(error)
                self?.onTaskFailed()
                self?.showOkAlert(title: Words.error.localized, msg: Words.errorGeneric.localized)
                return
            }
            
            guard let session = session else {
                print2("Twitter login error [2]")
                self?.onTaskFailed()
                self?.showOkAlert(title: Words.error.localized, msg: Words.errorGeneric.localized)
                return
            }
            
            print2("Twitter login proceed")
            let credential = TwitterAuthProvider.credential(withToken: session.authToken, secret: session.authTokenSecret)
            self?.viewModel.loginWithProvider(credential: credential)
        }
    }
    
    func showTermsOfUserAlert(source: AuthSource) {
        let alert = UIAlertController(title: Words.termsOfService.localized, message: Words.agreedTermsOfService.localized, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: Words.cancel.localized, style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { [weak self] _ in
            switch source {
            case .email:
                self?.signupProceed()
            case .fb:
                self?.fbLogin()
            }
        }))
        present(alert, animated: true, completion: nil)
    }
    
    // To be overriden
    func signupProceed() { }
    
}

extension BaseAuthViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        var resign = true
        
        if let formView = textField.superview as? FormTextField {
            let nextTag = formView.tag + 1
            print2("nextTag: \(nextTag)")

            if let nextResponder = textField.superview?.superview?.viewWithTag(nextTag) as? FormTextField {
                resign = true
                nextResponder.textField.becomeFirstResponder()
            }
        }

        if resign {
            textField.resignFirstResponder()
        }

        return true
    }
    
}
