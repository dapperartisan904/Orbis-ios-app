//
//  PostMenuViewController.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 12/03/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift

enum PostMenuOptions : CaseIterable {
    case deletePost, hidePost, reportPost
    
    func getWord() -> Words {
        switch self {
        case .deletePost:
            return Words.deletePost
        case .hidePost:
            return Words.hidePost
        case .reportPost:
            return Words.reportPost
        }
    }
}

/*
    Replaced by action sheet
 */
class PostMenuViewController : UIViewController {
    
    @IBOutlet weak var stackView: UIStackView!
    
    var viewModel: BasePostsViewModel!
    var post: OrbisPost!
    
    private let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for option in PostMenuOptions.allCases {
            let button = UIButton(type: .custom)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle(option.getWord().localized, for: .normal)
            button.setTitleColor(UIColor.black, for: .normal)
            button.makeFontSizeAdjustable()
            stackView.addArrangedSubview(button)
            
            button.rx.tap
                .bind { [weak self] in
                    guard let this = self else { return }
                    //this.viewModel.optionSelected(option: option, post: this.post)
                    this.dismiss(animated: true, completion: nil)
                }
                .disposed(by: bag)
        }
    }
    
}
