//
//  FirstViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 04/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {

    //@IBOutlet weak var button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func buttonClick(_ sender: Any) {
        showViewController(withInfo: ViewControllerInfo.createGroup)
    }
    
}

