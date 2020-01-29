//
//  PointsCell.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 30/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

protocol PointsCellDelegate : class {
    func nameClick(cell: PointsCell?)
}

class PointsCell : UITableViewCell {
    
    @IBOutlet weak var orderLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var percentageLabel: UILabel!
    
    weak var delegate: PointsCellDelegate?
    private let bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        nameLabel.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.nameClick(cell: self)
            })
            .disposed(by: bag)
    }
    
}
