//
//  PlaceDescriptionViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 16/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class PlaceDescriptionViewController : OrbisViewController, PlaceChildController {
    
    // Deprecated. Not removed only to avoid reorganize all constraints
    @IBOutlet weak var descTextField: FormTextField!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var pencilView: UIImageView!
    @IBOutlet weak var starView: UIImageView!
    @IBOutlet weak var dominatingGroupLabel: UILabel!
    @IBOutlet weak var dominatingPercentageLabel: UILabel!
    @IBOutlet weak var pieView: OrbisPie!
    @IBOutlet weak var strokeView: RoundedImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var descLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var dominatingGroupLeadingConstraint: NSLayoutConstraint!
    private weak var alert: UIAlertController?
    
    var placeViewModel: PlaceViewModel!
    private var dominatingFont: UIFont!
    private var secondaryFont: UIFont!
    
    override func shouldObserveActiveGroup() -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        descTextField.isHidden = true
        descTextField.textField.isUserInteractionEnabled = false
        
        descLabel.text = placeViewModel.place.description
        descLabel.isUserInteractionEnabled = false
        
        pencilView.image = UIImage(named: "baseline_create_black_48pt")?.template
        pencilView.tintColor = UIColor.lightGray
        pencilView.isHidden = true
        
        dominatingFont = UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.light)
        secondaryFont = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        
        dominatingGroupLabel.isHidden = true
        dominatingGroupLabel.font = dominatingFont
        dominatingPercentageLabel.isHidden = true
        dominatingPercentageLabel.font = dominatingFont
        
        pieView.translatesAutoresizingMaskIntoConstraints = false
        starView.isHidden = true
        
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.rowHeight = 40.0
        tableView.register(cell: Cells.points)
        tableView.dataSource = self
        
        updateLineView()
        
        [descLabel, pencilView].forEach { view in
            view.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    self?.showDescAlertController()
                })
                .disposed(by: bag)
        }
        
        dominatingGroupLabel.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                guard
                    let this = self,
                    let g = this.placeViewModel.getDominatingGroup()
                else {
                    return
                }
                
                this.handleNavigation(navigation: .group(group: g))
            })
            .disposed(by: bag)
        
        placeViewModel.pointsLoadedSubject
            .subscribe(onNext: { [weak self] loaded in
                guard
                    let this = self,
                    let points = this.placeViewModel.points,
                    loaded
                else {
                    return
                }
                
                this.indicatorView.stopAnimating()
                
                if this.placeViewModel.canEdit() {
                    this.descLabel.isUserInteractionEnabled = true
                    this.pencilView.isHidden = false
                }
                
                this.updatePieContraints(pointsCount: points.count)
                this.pieView.groups = this.placeViewModel.groups
                this.pieView.points = points
                this.tableView.reloadData()
                
                if let dg = this.placeViewModel.getDominatingGroup() {
                    var str = dg.name!
                    
                    if this.placeViewModel.groups?.count ?? 0 > 1 {
                        let labelSize = this.dominatingGroupLabel.size
                        let textSize = str.width(withConstrainedHeight: labelSize.height, font: this.dominatingFont)

                        if textSize < labelSize.width {
                            for _ in 0...10 {
                                str.append(".....................................................")
                            }
                        }
                        else {
                            str.append("...")
                            this.dominatingPercentageLabel.minimumScaleFactor = 0.3
                            this.dominatingGroupLabel.adjustsFontSizeToFitWidth = true
                        }
                    } else {
                        this.dominatingGroupLeadingConstraint.priority = .defaultLow
                    }
                    
                    this.strokeView.groupStroke(group: dg, width: 4.0)
                    this.dominatingGroupLabel.text = str
                    this.dominatingGroupLabel.isHidden = false

                    this.starView.image = UIImage(named: "ic_star_gray_2")?.template
                    this.starView.tint(activeGroup: dg, isSelected: true)
                    this.starView.isHidden = false
                }
                
                if this.placeViewModel.groups?.count ?? 0 < 2 {
                    this.dominatingPercentageLabel.text = ""
                } else {
                    this.dominatingPercentageLabel.text = "#\(this.placeViewModel.groups?.count ?? 0)"
                }

//                if let p = points.first {
//                    this.dominatingPercentageLabel.text = String(value: p.percentage, decimalPlaces: 2) + "%"
                    this.dominatingPercentageLabel.isHidden = false
//                }
            })
            .disposed(by: bag)
    }
    
    private func testConstraints() {
        pieView.backgroundColor = UIColor.red
        delay(ms: 2000, block: { self.updatePieContraints(pointsCount: 1) })
        delay(ms: 6000, block: { self.updatePieContraints(pointsCount: 1) })
        delay(ms: 10000, block: { self.updatePieContraints(pointsCount: 2) })
        delay(ms: 14000, block: { self.updatePieContraints(pointsCount: 2) })
        delay(ms: 18000, block: { self.updatePieContraints(pointsCount: 1) })
    }
    
    private func updatePieContraints(pointsCount: Int) {
        let leading = pieView.findConstraint(layoutAttribute: .leading, relatedTo: view)
        let centerX = pieView.findConstraint(layoutAttribute: .centerX, relatedTo: view)

        //print2("updatePieContraints pointsCount: \(pointsCount) leading is null: \(leading == nil) centerX is null: \(centerX == nil)")
        
        if pointsCount == 1 {
            if let leading = leading {
                leading.isActive = false
                pieView.superview?.removeConstraint(leading)
            }

            if centerX == nil {
                pieView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            }
        }
        else if pointsCount > 1 {
            if let centerX = centerX {
                centerX.isActive = false
                pieView.superview?.removeConstraint(centerX)
            }
            
            if leading == nil {
                pieView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26).isActive = true
            }
        }
    }
    
    private func showDescAlertController() {
        alert = showAlertWithTextView(
            title: Words.enterPlaceDescription.localized,
            placeholder: "",
            leftButtonTitle: Words.cancel.localized,
            rightButtonTitle: Words.ok.localized,
            initialText: descLabel.text,
            rightActionEnabled: true,
            textViewDelegate: nil,
            rightBlock: { [weak self] text in
                guard let this = self else { return }
                let str = text ?? ""
                this.placeViewModel.savePlaceDescription(text: str)
                this.descLabel.text = str
                this.updateLineView()
            }
        )
    }
    
    private func updateLineView() {
        let isEmpty = descLabel.text?.isEmpty ?? true
        lineView.isHidden = isEmpty && !placeViewModel.canEdit()
    }
}

extension PlaceDescriptionViewController : PointsCellDelegate {
    func nameClick(cell: PointsCell?) {
        guard
            let cell = cell,
            let indexPath = tableView.indexPath(for: cell)
        else {
            return
        }
        
        let points = placeViewModel.points![indexPath.row + 1]
        guard let g = placeViewModel.getGroup(groupKey: points.groupKey) else {
            return
        }
    
        handleNavigation(navigation: Navigation.group(group: g))
    }
}

extension PlaceDescriptionViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max((placeViewModel.points?.count ?? 0) - 1, 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withCellType: Cells.points, for: indexPath) as! PointsCell
        let points = placeViewModel.points![indexPath.row + 1]
        
        cell.delegate = self
        cell.orderLabel.text = (indexPath.row + 2).string + "."
        cell.orderLabel.font = secondaryFont
        
        cell.percentageLabel.text = String(value: points.percentage, decimalPlaces: 2) + "%"
        cell.percentageLabel.font = secondaryFont
        
        if let g = placeViewModel.getGroup(groupKey: points.groupKey) {
            var str = g.name!
            let labelSize = cell.nameLabel.size
            let textSize = str.width(withConstrainedHeight: labelSize.height, font: secondaryFont)
            
            if textSize < labelSize.width {
                cell.nameLabel.adjustsFontSizeToFitWidth = false
                for _ in 0...10 {
                    str.append(".....................................................")
                }
            }
            else {
                str.append("...")
                cell.nameLabel.minimumScaleFactor = 0.3
                cell.nameLabel.adjustsFontSizeToFitWidth = true
            }
            
            cell.nameLabel.font = secondaryFont
            cell.nameLabel.text = str
        }
        else {
            cell.nameLabel.text = ""
            cell.percentageLabel.text = ""
        }
        
        return cell
    }
    
}

extension PlaceDescriptionViewController : UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        print2("textFieldDidEndEditing \(String(describing: textField.text))")
        placeViewModel.savePlaceDescription(text: textField.text)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
