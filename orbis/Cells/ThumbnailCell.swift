//
//  ThumbnailCell.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 22/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

protocol ThumbnailCellDelegate : class {
    func removeViewClick(cell: ThumbnailCell)
}

class ThumbnailCell : UICollectionViewCell {
    
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var checkView: UIImageView!
    @IBOutlet weak var removeView: RoundedImageView!
    
    var representedAssetIdentifier: String?
    weak var delegate: ThumbnailCellDelegate?
    private let bag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        removeView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                guard let this = self else { return }
                this.delegate?.removeViewClick(cell: this)
            })
            .disposed(by: bag)
    }
}
