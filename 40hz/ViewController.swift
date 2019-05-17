//
//  ViewController.swift
//  40hz
//
//  Created by Johan Sellström on 2019-05-17.
//  Copyright © 2019 Johan Sellström. All rights reserved.
//

import UIKit

enum AudioMode {
    case iso // mono
    case tone // biaureal
}

class ViewController: UIViewController {

    @IBOutlet weak var tapIcon: UIImageView!
    let mode: AudioMode = .tone
    var isoGenerator: IsoGeneratorController?
    var toneGenerator: ToneGeneratorController?
    var isPlaying = false
    var flashView: UIView!

    func setup() {
        if mode == .iso {
            isoGenerator = IsoGeneratorController()
            isoGenerator?.setup()

        } else {
            toneGenerator = ToneGeneratorController()
            toneGenerator?.setup()
        }
        flashView = UIView(frame: view.frame)
        flashView.backgroundColor = .white
        flashView.alpha = 0.0
        view.addSubview(flashView)
        view.backgroundColor = .black
    }

    func start() {
        tapIcon.alpha = 0.0
        flashView.alpha = 1.0
    }

    func reset() {
        flashView.alpha = 0.0
        tapIcon.alpha = 1.0
        flashView.layer.removeAllAnimations()
    }

    func blink() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.duration = 0.0125
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.autoreverses = true
        animation.repeatCount = Float.greatestFiniteMagnitude
        flashView.layer.add(animation, forKey: "opacity")
      }


    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tooglePlay(_:)))
        view.addGestureRecognizer(tapGesture)
    }

    @objc func tooglePlay(_ sender: Any) {
        
        isPlaying = !isPlaying

        if mode == .iso, let isoGenerator = isoGenerator  {
            isoGenerator.togglePlay()
        } else if let toneGenerator = toneGenerator {
            toneGenerator.togglePlay()
        }

        if isPlaying {
            self.start()
            self.blink()
        } else {
            self.reset()
        }

    }

}

