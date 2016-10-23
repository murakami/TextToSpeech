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
    }
    
    override func viewWillDisappear() {
        dispose()
        super.viewWillDisappear()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    var auGraph: AUGraph? = nil
    
    func start() {
        var inputNode: AUNode = 0
        var effectNode: AUNode = 0
        var outputNode: AUNode = 0

        NewAUGraph(&auGraph);

        if let auGraph = self.auGraph {
            var	cd = AudioComponentDescription()
            cd.componentType = kAudioUnitType_Generator
            cd.componentSubType = kAudioUnitSubType_SpeechSynthesis
            cd.componentManufacturer = kAudioUnitManufacturer_Apple
            cd.componentFlags = 0
            cd.componentFlagsMask = 0

            AUGraphAddNode(auGraph, &cd, &inputNode)

            cd = setEffectNodeToDelay()
            AUGraphAddNode(auGraph, &cd, &effectNode)

            cd.componentType = kAudioUnitType_Output
            cd.componentSubType = kAudioUnitSubType_DefaultOutput
            AUGraphAddNode(auGraph, &cd, &outputNode)

            AUGraphConnectNodeInput(auGraph, inputNode, 0, effectNode, 0)
            AUGraphConnectNodeInput(auGraph, effectNode, 0, outputNode, 0)

            AUGraphOpen(auGraph)
            AUGraphInitialize(auGraph)

            var generateAudioUnit: AudioUnit? = nil
            AUGraphNodeInfo(auGraph, inputNode, nil, &generateAudioUnit)
            var channel: SpeechChannel? = nil
            var sz: UInt32 = UInt32(MemoryLayout<SpeechChannel>.size)
            AudioUnitGetProperty(generateAudioUnit!, kAudioUnitProperty_SpeechChannel, kAudioUnitScope_Global, 0, &channel, &sz)
            
            updateDelayParam(auGraph: auGraph, effectNode: effectNode)

            AUGraphStart(auGraph)

            if let textView = self.textView {
                SpeakCFString(channel!, textView.string! as NSString, nil)
            }
        }
    }
    
    func dispose() {
        if let auGraph = self.auGraph {
            AUGraphStop(auGraph)
            AUGraphUninitialize(auGraph)
            AUGraphClose(auGraph)
            DisposeAUGraph(auGraph)
            self.auGraph = nil
        }
    }
    
    @IBOutlet var textView: NSTextView?
    
    @IBAction func speak(sender: AnyObject) {
        dispose()
        start()
    }
    
    private func setEffectNodeToDelay() -> AudioComponentDescription {
        var	cd = AudioComponentDescription()
        cd.componentType = kAudioUnitType_Effect
        cd.componentSubType = kAudioUnitSubType_Delay
        cd.componentManufacturer = kAudioUnitManufacturer_Apple
        cd.componentFlags = 0
        cd.componentFlagsMask = 0
        return cd
    }
    
    private func updateDelayParam(auGraph: AUGraph, effectNode: AUNode) {
        var effectAudioUnit: AudioUnit? = nil
        AUGraphNodeInfo(auGraph, effectNode, nil, &effectAudioUnit)
        setFloatValue(unit: effectAudioUnit!, paramID: kDelayParam_WetDryMix, value: 50.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kDelayParam_DelayTime, value: 1.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kDelayParam_Feedback, value: 50.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kDelayParam_LopassCutoff, value: 15000.0)
    }

    private func setFloatValue(unit: AudioUnit, paramID: AudioUnitParameterID, value: Float) {
        AudioUnitSetParameter(unit, paramID, kAudioUnitScope_Global, 0, value, 0)
    }
}

