//
//  CreateEventViewController.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 29/04/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

/*
    Used for edit event too
 */
class CreateEventViewController : OrbisViewController {
    
    @IBOutlet weak var toolbar: TitleToolbar!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var linkIcon: UIImageView!
    @IBOutlet weak var linkLabel: UILabel!
    @IBOutlet weak var addressIcon: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var timeIcon: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var dateIcon: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var detailsLabel2: UILabel!
    @IBOutlet weak var detailsPlaceholderLabel: UILabel!
    @IBOutlet weak var mainButton: BottomButton!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var deleteLabel: UILabel!
    @IBOutlet weak var deleteIcon: UIImageView!
    
    private var alert: UIAlertController?
    private var datePicker: UIDatePicker?
    
    var viewModel: CreateEventViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        toolbar.label.text = Words.choosePlaceName.localized
        toolbar.delegate = self
        addressLabel.text = viewModel.place.name
        detailsLabel.text = Words.details.localized
        detailsPlaceholderLabel.text = Words.writeHere.localized
        indicatorView.isHidden = true
        updateFields()

        if viewModel.editing {
            toolbar.label.text = Words.editEvent.localized
            mainButton.setTitle(Words.saveChanges.localized, for: .normal)
            deleteLabel.text = Words.delete.localized.uppercased()
            deleteIcon.tintColor = UIColor.red
            
            [deleteLabel, deleteIcon].forEach { v in
                v.rx.tapGesture()
                    .when(.recognized)
                    .subscribe(onNext: { [weak self] _ in
                        self?.viewModel.delete()
                    })
                    .disposed(by: bag)
            }
        }
        else {
            toolbar.label.text = Words.createEvent.localized
            mainButton.setTitle(Words.create.localized, for: .normal)
            deleteLabel.isHidden = true
            deleteIcon.isHidden = true
        }
        
        nameLabel.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.showNameAlert()
            })
            .disposed(by: bag)
        
        [linkLabel, linkIcon].forEach { v in
            v.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    self?.showLinkAlert()
                })
                .disposed(by: bag)
        }
        
        [timeLabel, timeIcon].forEach { v in
            v.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    self?.showTimeAlert()
                })
                .disposed(by: bag)
        }
        
        [dateLabel, dateIcon].forEach { v in
            v.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    self?.showDateAlert()
                })
                .disposed(by: bag)
        }
        
        [detailsLabel, detailsLabel2, detailsPlaceholderLabel].forEach { v in
            v.rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { [weak self] _ in
                    self?.showDetailsAlert()
                })
                .disposed(by: bag)
        }
        
        mainButton.rx.tap
            .bind { [weak self] in
                self?.viewModel.save()
            }
            .disposed(by: bag)
        
        observeDefaultSubject(subject: viewModel.defaultSubject)
    }
    
    private func showNameAlert() {
        alert?.dismiss(animated: true, completion: nil)
        
        alert = showAlertWithTextField(
            title: Words.enterEventName.localized,
            placeholder: Words.typeHere.localized,
            leftButtonTitle: Words.cancel.localized,
            rightButtonTitle: Words.ok.localized,
            rightActionEnabled: true,
            textFieldDelegate: self,
            rightBlock: { [weak self] text in
                self?.viewModel.name = text
                self?.updateFields()
            }
        )
    }
    
    private func showLinkAlert() {
        alert?.dismiss(animated: true, completion: nil)
        
        alert = showAlertWithTextField(
            title: Words.enterEventLink.localized,
            placeholder: Words.typeHere.localized,
            leftButtonTitle: Words.cancel.localized,
            rightButtonTitle: Words.ok.localized,
            rightActionEnabled: true,
            textFieldDelegate: self,
            rightBlock: { [weak self] text in
                self?.viewModel.link = text
                self?.updateFields()
            }
        )
    }
    
    private func showDetailsAlert() {
        alert?.dismiss(animated: true, completion: nil)
        
        alert = showAlertWithTextView(
            title: Words.describeEventDetails.localized,
            placeholder: "",
            leftButtonTitle: Words.cancel.localized,
            rightButtonTitle: Words.ok.localized,
            initialText: detailsLabel2.text,
            rightActionEnabled: true,
            textViewDelegate: self,
            rightBlock: { [weak self] text in
                self?.viewModel.details = text
                self?.updateFields()
            }
        )
    }
    
    private func showTimeAlert() {
        alert?.dismiss(animated: true, completion: nil)
        
        alert = showDatePicker(
            mode: UIDatePicker.Mode.time,
            title: Words.date.localized,
            leftButtonTitle: Words.cancel.localized,
            rightButtonTitle: Words.ok.localized,
            rightBlock: { [weak self] date in
                self?.viewModel.time = date
                self?.updateFields()
            })
    }
    
    private func showDateAlert() {
        alert?.dismiss(animated: true, completion: nil)
        
        alert = showDatePicker(
            mode: UIDatePicker.Mode.date,
            title: Words.date.localized,
            leftButtonTitle: Words.cancel.localized,
            rightButtonTitle: Words.ok.localized,
            rightBlock: { [weak self] date in
                self?.viewModel.date = date
                self?.updateFields()
            })
    }
    
    private func updateFields() {
        nameLabel.text = viewModel.name ?? Words.eventName.localized
        linkLabel.text = viewModel.link ?? Words.link.localized
        detailsLabel2.text = viewModel.details
        detailsPlaceholderLabel.isHidden = viewModel.details?.isEmpty ?? true

        if let time = viewModel.time {
            let df = DateFormatter()
            df.dateStyle = .none
            df.timeStyle = .short
            timeLabel.text = df.string(from: time)
        }
        else {
            timeLabel.text = Words.hour.localized
        }

        if let date = viewModel.date {
            let df = DateFormatter()
            df.dateStyle = .short
            df.timeStyle = .none
            dateLabel.text = df.string(from: date)
        }
        else {
            dateLabel.text = Words.date.localized
        }
    }
    
    override func onTaskStarted() {
        indicatorView.isHidden = false
        indicatorView.startAnimating()
    }
    
    override func onTaskFailed() {
        indicatorView.stopAnimating()
        indicatorView.isHidden = true
    }

    override func onTaskFinished() {
        indicatorView.stopAnimating()
        indicatorView.isHidden = true
        navigationController?.popViewController(animated: true)
    }

}

extension CreateEventViewController : UITextFieldDelegate {
    
}

extension CreateEventViewController : UITextViewDelegate {
    
}
