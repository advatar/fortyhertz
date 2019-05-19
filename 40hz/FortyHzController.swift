//
//  ViewController.swift
//  40hz
//
//  Created by Johan Sellström on 2019-05-17.
//  Copyright © 2019 Johan Sellström. All rights reserved.
//

import UIKit
import AVFoundation

public enum FortyHertzAudioMode {
    case iso // mono
    case tone // biaureal
}

public class FortyHertzController {

    var mode: FortyHertzAudioMode = .tone
    var isoGenerator: IsoGeneratorController?
    var toneGenerator: ToneGeneratorController?
    var isPlaying = false
    var flashView: UIView!
    let device = AVCaptureDevice.default(for: .video)
    var timerSpeed: Double = 0.0
    var onTime:Double = 0.0125
    var offTime:Double = 0.0125
    var onTimer: Timer?
    var offTimer: Timer?
    init(on view: UIView, mode: FortyHertzAudioMode) {

        if mode == .iso {
            isoGenerator = IsoGeneratorController()
            isoGenerator?.setup()

        } else {
            toneGenerator = ToneGeneratorController()
            toneGenerator?.setup()
        }
        self.mode = mode
        flashView = UIView(frame: view.frame)
        flashView.backgroundColor = .white
        flashView.alpha = 0.0
        view.addSubview(flashView)
        view.backgroundColor = .black
    }


    func start() {
        //flashView.alpha = 1.0
    }

    func reset() {
        flashView.alpha = 0.0
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

    @objc func lightOn() {
        if let device = device, device.hasTorch {
            do {
                try device.lockForConfiguration()
                    try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                device.unlockForConfiguration()
                //offTimer?.invalidate()
                onTimer = Timer.scheduledTimer(timeInterval: onTime, target: self, selector: #selector(lightOff), userInfo: nil, repeats: false)
            } catch {
                print(error)
            }
        }
    }

    @objc func lightOff() {
        if let device = device, device.hasTorch {
            do {
                try device.lockForConfiguration()
                    try device.setTorchModeOn(level: 0.5)
                device.unlockForConfiguration()
                //onTimer?.invalidate()
                offTimer = Timer.scheduledTimer(timeInterval: onTime, target: self, selector: #selector(lightOn), userInfo: nil, repeats: false)
            } catch {
                print(error)
            }
        }
    }

    func turnOn() {
        if let device = device, device.hasTorch {
            do {
                try device.lockForConfiguration()
                    device.torchMode = .on
                device.unlockForConfiguration()
                onTimer?.invalidate()
                offTimer?.invalidate()
            } catch {
                print(error)
            }
        }
    }

    func turnOff() {
        if let device = device, device.hasTorch {
            do {
                try device.lockForConfiguration()
                    device.torchMode = .off
                device.unlockForConfiguration()
                onTimer?.invalidate()
                offTimer?.invalidate()
            } catch {
                print(error)
            }
        }
    }

    func strobe(isOn: Bool) {
        switch isOn {
        case true:
            turnOn()
            lightOn()
        case false:
            turnOff()
        }
    }

    func tooglePlay() {
        isPlaying = !isPlaying
        if mode == .iso, let isoGenerator = isoGenerator  {
            isoGenerator.togglePlay()
        } else if let toneGenerator = toneGenerator {
            toneGenerator.togglePlay()
        }
        self.strobe(isOn: isPlaying)
        if isPlaying {
            self.start()
            //self.blink()
        } else {
            self.reset()
        }
    }

}

