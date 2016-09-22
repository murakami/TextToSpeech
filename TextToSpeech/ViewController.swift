//
//  ViewController.swift
//  TextToSpeech
//
//  Created by Yukio MURAKAMI on 2016/09/15.
//  Copyright © 2016年 Bitz Co., Ltd. All rights reserved.
//

import Cocoa
import AudioUnit
import AudioToolbox
import CoreAudioKit

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        demo()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    var auGraph: AUGraph? = nil
    
    func demo() {
        var inputNode: AUNode = 0
        var effectNode: AUNode = 0
        var outputNode: AUNode = 0
        
        NewAUGraph(&auGraph);
        
        var	cd = AudioComponentDescription()
        cd.componentType = kAudioUnitType_Generator
        cd.componentSubType = kAudioUnitSubType_SpeechSynthesis
        cd.componentManufacturer = kAudioUnitManufacturer_Apple
        cd.componentFlags = 0
        cd.componentFlagsMask = 0
        
        AUGraphAddNode(auGraph!, &cd, &inputNode)
        
        cd.componentType = kAudioUnitType_Effect
        cd.componentSubType = kAudioUnitSubType_Delay
        AUGraphAddNode(auGraph!, &cd, &effectNode)
        
        cd.componentType = kAudioUnitType_Output
        cd.componentSubType = kAudioUnitSubType_DefaultOutput
        AUGraphAddNode(auGraph!, &cd, &outputNode)
        
        AUGraphConnectNodeInput(auGraph!, inputNode, 0, effectNode, 0)
        AUGraphConnectNodeInput(auGraph!, effectNode, 0, outputNode, 0)
        
        AUGraphOpen(auGraph!)
        AUGraphInitialize(auGraph!)
        
        var generateAudioUnit: AudioUnit? = nil
        AUGraphNodeInfo(auGraph!, inputNode, nil, &generateAudioUnit)
        var channel: SpeechChannel? = nil
        var sz: UInt32 = UInt32(MemoryLayout<SpeechChannel>.size)
        AudioUnitGetProperty(generateAudioUnit!, kAudioUnitProperty_SpeechChannel, kAudioUnitScope_Global, 0, &channel, &sz)
        
        AUGraphStart(auGraph!)
        
        SpeakCFString(channel!, "Nice to meet you. It's nice to see you! Nice meeting you. I'm pleased to meet you. Please say hello to your family. I look forward to seeing you again. Yes. Let's get together soon." as NSString, nil)
    }
    
    func dispose() {
        AUGraphStop(auGraph!)
        AUGraphUninitialize(auGraph!)
        AUGraphClose(auGraph!)
        DisposeAUGraph(auGraph!)
        auGraph = nil
    }

}

