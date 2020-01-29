//
//  MemberMenuViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 25/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

enum MemberMenuOptions {
    case makeAdmin, removeAdmin, ban

    func getWord() -> Words {
        switch self {
        case .makeAdmin:
            return Words.menuMakeAdministrator
        case .removeAdmin:
            return Words.menuRemoveAdmin
        case .ban:
            return Words.menuBan
        }
    }
}

class MemberMenuViewController : UIViewController {
    
    @IBOutlet weak var stackView: UIStackView!
    
    var viewModel: UsersOfGroupViewModel!
    var user: OrbisUser!
    var options: [MemberMenuOptions]!

    private let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for option in options {
            let button = UIButton(type: .custom)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle(option.getWord().localized, for: .normal)
            button.setTitleColor(UIColor.black, for: .normal)
            button.makeFontSizeAdjustable()
            stackView.addArrangedSubview(button)
            
            button.rx.tap
                .bind { [weak self] in
                    guard let this = self else { return }
                    this.viewModel.optionSelected(option: option, user: this.user)
                    this.dismiss(animated: true, completion: nil)
                }
                .disposed(by: bag)
        }
    }
    
}
