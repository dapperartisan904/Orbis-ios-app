//
//  LoginViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 10/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import Firebase
import FBSDKLoginKit
import TwitterKit
import MKProgress

class LoginViewController : BaseAuthViewController {
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var forgotPwdLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        usernameField.textField.delegate = self
        pwdField.textField.delegate = self
        usernameField.tag = 0
        pwdField.tag = 1
        
        loginButton.setTitle(Words.login.localized, for: .normal)
        forgotPwdLabel.text = Words.forgotPassword.localized
        
        loginButton.rx.tap
            .bind { [weak self] in
                guard let this = self else { return }
                this.viewModel.signIn(username: this.usernameField.getText(), pwd: this.pwdField.getText())
            }
            .disposed(by: bag)
        
        forgotPwdLabel.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.showViewController(withInfo: .forgotPassword)
            })
            .disposed(by: bag)
    }
    
}
