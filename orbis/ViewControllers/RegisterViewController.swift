//
//  RegisterViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 22/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class RegisterViewController : BaseAuthViewController {
    
    @IBOutlet weak var emailField: FormTextField!
    @IBOutlet weak var repeatPwdField: FormTextField!
    @IBOutlet weak var registerButton: DarkGrayButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameField.textField.delegate = self
        emailField.textField.delegate = self
        pwdField.textField.delegate = self
        repeatPwdField.textField.delegate = self
        usernameField.tag = 0
        emailField.tag = 1
        pwdField.tag = 2
        repeatPwdField.tag = 3
        
        emailField.asEmail()
        repeatPwdField.asPwd()
        emailField.setText(text: nil, placeholder: Words.email.localized)
        repeatPwdField.setText(text: nil, placeholder: Words.repeatPassword.localized)
        registerButton.setTitle(Words.register.localized, for: .normal)
        
        if #available(iOS 11.0, *) {
            repeatPwdField.textField.textContentType = UITextContentType.password
        }
        
        registerButton.rx.tap
            .bind { [weak self] in
                guard let this = self else { return }
                this.showTermsOfUserAlert(source: .email)
            }
            .disposed(by: bag)        
    }
    
    override func signupProceed() {
         viewModel.signUp(
            username: usernameField.getText(),
            email: emailField.getText(),
            pwd: pwdField.getText(),
            pwd2: repeatPwdField.getText()
        )
    }
    
}
