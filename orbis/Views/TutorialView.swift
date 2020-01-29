//
//  TutorialView.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 24/05/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class TutorialView : UIView {
    
    class func createAndAttachToContainer(container: UIView) -> TutorialView {
        let tv = UIView.loadFromNib(named: "TutorialView") as! TutorialView
        tv.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tv)
        tv.anchorToSuperview()
        return tv
    }

    @IBOutlet weak var closeButton: UIImageView!
    @IBOutlet weak var nextButton: UIImageView!
    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var tutorial2Container: UIView!
    @IBOutlet weak var tutorial3Container: UIView!
    @IBOutlet weak var tutorial4Container: UIView!
    @IBOutlet weak var tutorial5Container: UIView!
    @IBOutlet weak var tutorial7Container: UIView!
    @IBOutlet weak var tutorial8Container: UIView!
    @IBOutlet weak var label10: UILabel!
    @IBOutlet weak var label11: UILabel!
    @IBOutlet weak var label30: UILabel!
    @IBOutlet weak var label40: UILabel!
    @IBOutlet weak var label51: UILabel!
    @IBOutlet weak var myFeedLabel: UILabel!
    @IBOutlet weak var distanceFeedLabel: UILabel!
    
    private let bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let lightFont = UIFont.systemFont(ofSize: 20.0, weight: .light)
        let regularFont = UIFont.systemFont(ofSize: 20.0, weight: .regular)
        
        [tutorial2Container, tutorial3Container, tutorial4Container].forEach {
            guard let container = $0 else { return }
            container.isHidden = true
            
            for child in container.subviews {
                guard let label = child as? UILabel else { continue }
                label.textAlignment = .center
                label.numberOfLines = 0
                
                if label == myFeedLabel || label == distanceFeedLabel {
                    label.font = regularFont
                    label.textColor = UIColor.darkGray
                }
                else {
                    label.font = lightFont
                    label.textColor = UIColor.white
                }
            }
        }
    
        closeButton.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.isHidden = true
            })
            .disposed(by: bag)
        
        label10.text = Words.tutorial_1_0.localized
        label11.text = Words.tutorial_1_1.localized
        label30.text = Words.tutorial_3_0.localized
        label40.text = Words.tutorial_4_0.localized
        //label51.text = Words.tutorial_5_1.localized
        myFeedLabel.text = Words.myFeed.localized
        
        nextButton.isHidden = true
        
        tutorial4Container.isHidden = false
    }
    
}
