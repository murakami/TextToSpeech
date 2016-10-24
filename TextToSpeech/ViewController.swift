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

            cd = setEffectNode(subType: kAudioUnitType_Effect)
            //cd = setEffectNode(subType: kAudioUnitSubType_Distortion)
            //cd = setEffectNode(subType: kAudioUnitSubType_LowPassFilter)
            //cd = setEffectNode(subType: kAudioUnitSubType_HighPassFilter)
            //cd = setEffectNode(subType: kAudioUnitSubType_MatrixReverb)
            //cd = setEffectNode(subType: kAudioUnitSubType_Pitch)
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
            //updateDistortionParam(auGraph: auGraph, effectNode: effectNode)
            //updateLowPassFilterParam(auGraph: auGraph, effectNode: effectNode)
            //updateHighPassFilterParam(auGraph: auGraph, effectNode: effectNode)
            //updateMatrixReverbParam(auGraph: auGraph, effectNode: effectNode)
            //updatePitchParam(auGraph: auGraph, effectNode: effectNode)

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
    
    private func setEffectNode(subType: UInt32) -> AudioComponentDescription {
        var	cd = AudioComponentDescription()
        cd.componentType = kAudioUnitType_Effect
        cd.componentSubType = subType
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
    
    private func updateDistortionParam(auGraph: AUGraph, effectNode: AUNode) {
        var effectAudioUnit: AudioUnit? = nil
        AUGraphNodeInfo(auGraph, effectNode, nil, &effectAudioUnit)
        setFloatValue(unit: effectAudioUnit!, paramID: kDistortionParam_Delay, value: 0.1)
        setFloatValue(unit: effectAudioUnit!, paramID: kDistortionParam_Decay, value: 1.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kDistortionParam_DelayMix, value: 50.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kDistortionParam_Decimation, value: 50.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kDistortionParam_Rounding, value: 0.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kDistortionParam_DecimationMix, value: 50.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kDistortionParam_LinearTerm, value: 1.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kDistortionParam_SquaredTerm, value: 0.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kDistortionParam_CubicTerm, value: 0.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kDistortionParam_PolynomialMix, value: 50.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kDistortionParam_RingModFreq1, value: 100.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kDistortionParam_RingModFreq2, value: 100.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kDistortionParam_RingModBalance, value: 50.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kDistortionParam_RingModMix, value: 0.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kDistortionParam_SoftClipGain, value: -6.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kDistortionParam_FinalMix, value: 50.0)
    }
    
    private func updateLowPassFilterParam(auGraph: AUGraph, effectNode: AUNode) {
        var effectAudioUnit: AudioUnit? = nil
        AUGraphNodeInfo(auGraph, effectNode, nil, &effectAudioUnit)
        setFloatValue(unit: effectAudioUnit!, paramID: kLowPassParam_CutoffFrequency, value: 6900.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kLowPassParam_Resonance, value: 0.0)
    }
    
    private func updateHighPassFilterParam(auGraph: AUGraph, effectNode: AUNode) {
        var effectAudioUnit: AudioUnit? = nil
        AUGraphNodeInfo(auGraph, effectNode, nil, &effectAudioUnit)
        setFloatValue(unit: effectAudioUnit!, paramID: kHipassParam_CutoffFrequency, value: 6900.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kHipassParam_Resonance, value: 0.0)
    }
    
    private func updateMatrixReverbParam(auGraph: AUGraph, effectNode: AUNode) {
        var effectAudioUnit: AudioUnit? = nil
        AUGraphNodeInfo(auGraph, effectNode, nil, &effectAudioUnit)
        setFloatValue(unit: effectAudioUnit!, paramID: kReverbParam_DryWetMix, value: 100.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kReverbParam_SmallLargeMix, value: 50.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kReverbParam_SmallSize, value: 0.06)
        setFloatValue(unit: effectAudioUnit!, paramID: kReverbParam_LargeSize, value: 3.07)
        setFloatValue(unit: effectAudioUnit!, paramID: kReverbParam_PreDelay, value: 0.025)
        setFloatValue(unit: effectAudioUnit!, paramID: kReverbParam_LargeDelay, value: 0.035)
        setFloatValue(unit: effectAudioUnit!, paramID: kReverbParam_SmallDensity, value: 0.28)
        setFloatValue(unit: effectAudioUnit!, paramID: kReverbParam_LargeDensity, value: 0.82)
        setFloatValue(unit: effectAudioUnit!, paramID: kReverbParam_LargeDelayRange, value: 0.3)
        setFloatValue(unit: effectAudioUnit!, paramID: kReverbParam_SmallBrightness, value: 0.96)
        setFloatValue(unit: effectAudioUnit!, paramID: kReverbParam_LargeBrightness, value: 0.49)
        setFloatValue(unit: effectAudioUnit!, paramID: kReverbParam_SmallDelayRange, value: 0.5)
        setFloatValue(unit: effectAudioUnit!, paramID: kReverbParam_ModulationRate, value: 1.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kReverbParam_ModulationDepth, value: 0.2)
    }
    
    private func updatePitchParam(auGraph: AUGraph, effectNode: AUNode) {
        var effectAudioUnit: AudioUnit? = nil
        AUGraphNodeInfo(auGraph, effectNode, nil, &effectAudioUnit)
        setFloatValue(unit: effectAudioUnit!, paramID: kNewTimePitchParam_Rate, value: 1.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kNewTimePitchParam_Pitch, value: 1.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kNewTimePitchParam_Overlap, value: 8.0)
        setFloatValue(unit: effectAudioUnit!, paramID: kNewTimePitchParam_EnablePeakLocking, value: 1.0)
    }

    private func setFloatValue(unit: AudioUnit, paramID: AudioUnitParameterID, value: Float) {
        AudioUnitSetParameter(unit, paramID, kAudioUnitScope_Global, 0, value, 0)
    }
}

