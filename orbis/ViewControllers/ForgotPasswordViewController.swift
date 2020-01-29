//
//  ForgotPasswordViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 05/02/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxFirebaseDatabase
import FirebaseAuth
import RxSwift
import RxCocoa
import RxGesture

class ForgotPasswordViewController : OrbisViewController {
    
    @IBOutlet weak var toolbar: BaseToolbar!
    @IBOutlet weak var emailField: FormTextField!
    @IBOutlet weak var sendButton: DarkGrayButton!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbar.delegate = self
        
        indicatorView.stopAnimating()
        indicatorView.isHidden = true
        
        label.text = Words.forgotPassword.localized.uppercased()
        label2.text = Words.forgotPasswordInstructions.localized
        
        emailField.setText(text: nil, placeholder: Words.email.localized)
        emailField.asEmail()
        
        sendButton.setTitle(Words.send.localized, for: .normal)
        
        sendButton.rx.tap
            .bind { [weak self] _ in
                self?.resetPassword()
            }
            .disposed(by: bag)
    }
    
    private func resetPassword() {
        let email = emailField.getText() ?? ""
        
        if !email.isValidEmail {
            showOkAlert(title: Words.error.localized, msg: Words.invalidEmail.localized)
            return
        }

        indicatorView.isHidden = false
        indicatorView.startAnimating()
        
        let auth = Auth.auth()
        
        auth.rx.sendPasswordReset(withEmail: email)
            .subscribe(onCompleted: { [weak self] in
                self?.showOkAlert(title: Words.emailSent.localized, msg: Words.checkInbox.localized)
                self?.indicatorView.stopAnimating()
                self?.indicatorView.isHidden = true
            }, onError: { [weak self] error in
                print2(error)
                self?.showOkAlert(title: Words.error.localized, msg: Words.errorGeneric.localized)
                self?.indicatorView.stopAnimating()
                self?.indicatorView.isHidden = true
            })
            .disposed(by: bag)
    }
    
}
