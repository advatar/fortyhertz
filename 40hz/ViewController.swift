//
//  ViewController.swift
//  40hz
//
//  Created by Johan Sellström on 2019-05-17.
//  Copyright © 2019 Johan Sellström. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tapIcon: UIImageView!
    var controller: FortyHertzController?
    override func viewDidLoad() {
        super.viewDidLoad()
        controller = FortyHertzController(on: view, mode: .iso)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(togglePlay(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    @objc func togglePlay(_ sender: Any) {
        controller?.tooglePlay()
    }
}

