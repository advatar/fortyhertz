//
//  Binaural.swift
//  40hz
//
//  Created by Johan Sellström on 2019-05-17.
//  Copyright © 2019 Johan Sellström. All rights reserved.
//

import Foundation
import AudioUnit
import AVFoundation
import MediaPlayer


/*
func RenderIso(
    inRefCon:UnsafeMutableRawPointer,
    ioActionFlags:UnsafeMutablePointer<AudioUnitRenderActionFlags>,
    inTimeStamp:UnsafePointer<AudioTimeStamp>,
    inBusNumber:UInt32,
    inNumberFrames:UInt32,
    ioData:UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {

    let opaquePtr = OpaquePointer(inRefCon)
    var generator = UnsafeMutablePointer<IsoGenerator>(opaquePtr)
    let fader = generator->multiplier

    //- 400


    let mono_theta_increment: Float = Float(2.0*M_PI) * monoFrequency / Float(sampleRate)
    let monoChannel = 0

    var monoBuffer = ioData?[monoChannel].mBuffers.mData

    var frame: UInt32 = 0


    for frame in 0...inNumberFrames-1 {

    }

    return noErr
}
*/

class IsoGenerator {

    static let shared = IsoGenerator()
    var multiplier: Int = 0
    var carrierFrequency: Float = 200.0
    var monoFrequency: Float = 200.0
    var binauralFrequency: Float = 40.0
    var sampleRate: Int = 48000

    var frame = 0

    init() {

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let commandCenter = MPRemoteCommandCenter.shared
            multiplier = sampleRate/2
            multiplier = Int(Float(multiplier)/binauralFrequency)
            binauralFrequency = Float(sampleRate)/2.0
            binauralFrequency = binauralFrequency/Float(multiplier)
            //UIApplication.shared.beginReceivingRemoteControlEvents()
        } catch {
            print(error)
        }
    }

/*
    func createToneUnit() {

        var defaultOutputDescription = AudioComponentDescription(componentType: kAudioUnitType_Output, componentSubType: kAudioUnitSubType_RemoteIO, componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0)

        guard let defaultOutput = AudioComponentFindNext(nil, &defaultOutputDescription) else {
            fatalError("Can't find default output")
        }

        var toneUnit: AudioComponentInstance?

        let instance = AudioComponentInstanceNew(defaultOutput,&toneUnit)

        let input = AURenderCallbackStruct(inputProc: RenderIso, inputProcRefCon: self)

    }

 */
    
}
