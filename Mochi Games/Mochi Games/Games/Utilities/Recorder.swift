//
//  Recorder.swift
//  Mochi Games
//
//  Created by Sam Weekes on 5/29/20.
//  Copyright © 2020 Sam Weekes. All rights reserved.
//

import Foundation
import ReplayKit

protocol RecorderDelegate {
    func RecordingDidStart(successful : Bool)
    func RecordingDidFinish(url : URL?)
    func RecordingDeniedPermissions()
}

class Recorder : NSObject {
    
    // - screenRecorder is just cause i'm being lazy and can't be bothered to write out RPScreenRecorder.shared() all the time
    let screenRecorder = RPScreenRecorder.shared()
    
    var isAvailable : Bool {
        return self.screenRecorder.isAvailable
    }
    
    var isRecording : Bool {
        return self.screenRecorder.isRecording
    }
    
    var microphoneEnabled : Bool {
        return false // self.screenRecorder.isMicrophoneEnabled
    }
    
    var delegate : RecorderDelegate?
    
    private var assetWriter : AVAssetWriter?
    private var videoInput : AVAssetWriterInput?
    private var audioInput : AVAssetWriterInput?
    private let recordedFileNamePrefix : String = "Recording_"
    private let recordedFileNameFileType : String = ".mp4"
    private var recordedFileNameFull : String { // TODO: - SORT THIS OUT!
        return "\(self.recordedFileName).mp4"
    }
    private var recordedFileName : String = ""
    
    private var hasStartedRecording : Bool = false
    var outputURL : URL?
    
    override init() {
        super.init()
        self.screenRecorder.delegate = self
        self.recordedFileName = "Dance_\(UUID().uuidString)"
    }
    
    public func requestRecordPermission() {
        requestRecordPermissionsTest()
    }
    
    private func stopRequestRecordPermissionTest() {
        print("!! _ _ is recording? = \(self.isRecording)")
        self.screenRecorder.stopRecording { (_, error) in
            print("!! - - stop error = \(error)")
        }
    }
    
    private func requestRecordPermissionsTest() {
        print("!! _ _ is recording? = \(self.isRecording)")
        self.screenRecorder.startRecording { (error) in
            print("!! _ _ error = \(error)")
            guard let error = error else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.stopRequestRecordPermissionTest()
                }
                return
            }
            
            // - FOR ALL CODES - https://developer.apple.com/documentation/replaykit/rprecordingerrorcode
            let errorCode = (error as NSError).code
            let rpError = RPRecordingErrorCode(rawValue: errorCode)
            
            self.delegate?.RecordingDeniedPermissions()
            
        }
    }
    
    
    
    public func startRecording() {
        print("!! - start record recorder")
        self.startScreenCaptureSaveToFile()
    }
    
    public func stopRecording() {
        print("!! - stop record recorder")
        self.stopScreenCapture()
    }
    
    private func startScreenCaptureSaveToFile() {
        self.hasStartedRecording = false
        self.outputURL = nil
        
        let documentDirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        let fileManager = FileManager.default
        
        let fullPath = documentDirPath?.appending("/\(FileHandler.folderName)/\(self.recordedFileNameFull)")
        print("!! - full path = \(fullPath!)")
        
        if fileManager.fileExists(atPath : fullPath!) {
            do {
                try fileManager.removeItem(atPath: fullPath!)
            } catch {
                print("!! - - error removing existing recording - \(self.recordedFileNameFull) = \(error)")
            }
        }
        
        self.setUpMP4CaptureToAssetWriting(fileName: self.recordedFileName)
        
        guard let safeAssetWriter = self.assetWriter else {
            print("!! - - error setting up asset writer ")
            return
        }
        
        self.hasStartedRecording = true
        self.screenRecorder.startCapture(handler: { (samples, sampleType, error) in
            if CMSampleBufferDataIsReady(samples) {
                DispatchQueue.main.async { [weak self] in
                    if safeAssetWriter.status == .unknown {
                        if !safeAssetWriter.startWriting() {
                            return
                        }
                        safeAssetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(samples))
                    }
                
                if safeAssetWriter.status == .failed {
//                    print("!! - - status = failed")
//                    print("!! - - error = \(safeAssetWriter.error)")
                }
                
                if safeAssetWriter.status == .writing {
//                    print("!! - - status = writing")
                }
                
                if safeAssetWriter.status == .cancelled {
//                    print("!! - - status = cancelled")
                }
                
                if safeAssetWriter.status == .completed {
//                    print("!! - - status = completed")
                }
                
                if safeAssetWriter.status != .writing {
                    // either failed or cancelled -
                    if safeAssetWriter.status == .failed {
                        self?.delegate?.RecordingDidStart(successful: false)
                    }
                    return
                }
                
                let numSamples = CMSampleBufferGetNumSamples(samples)
                if numSamples > 0 {
                    switch sampleType {
                    case .video:
                        guard let safeVideoInput = self?.videoInput, safeVideoInput.isReadyForMoreMediaData == true else {
                            print("!! - video not ready for more data")
                            return
                        }
                        if safeAssetWriter.status == .writing {
                            if self!.hasStartedRecording {
                                safeVideoInput.append(samples)
                            }
                        }
                    case .audioApp:
                        guard let safeAudioInput = self?.audioInput, safeAudioInput.isReadyForMoreMediaData == true else {
                            print("!! - audio not ready for more data")
                            return
                        }
                        if safeAssetWriter.status == .writing {
                            if self!.hasStartedRecording {
                                safeAudioInput.append(samples)
                            }
                        }
                    default:
                        //
                        print("!! - default")
                    }
                }

                    }
            }
        }) { (error) in
            guard let err = error else {
                self.delegate?.RecordingDidStart(successful: true)
                return
            }
            print("!! - - - error = \(err)")
            self.delegate?.RecordingDidStart(successful: false)
        }
        
    }
    
    private func stopScreenCapture() {
        self.screenRecorder.stopCapture { (error) in
            if error != nil {
                print("!! - err on stop = \(String(describing: error))")
                self.delegate?.RecordingDidFinish(url: nil)
                return
            }
            guard let safeAssetWriter = self.assetWriter else {
                print("!! - err on asset writer")
                self.delegate?.RecordingDidFinish(url: nil)
                return
            }
            self.hasStartedRecording = false
            
            DispatchQueue.global(qos: .background).async {
                safeAssetWriter.finishWriting {
                    
                    if FileHandler.fetchAllReplays().count == 0 {
                        print("!! - cant get recorded file")
                        self.delegate?.RecordingDidFinish(url: nil)
                        return
                    }
                    
                    var i = 0
                    for (j, url) in FileHandler.fetchAllReplays().enumerated() {
                        if url.absoluteString.contains(self.recordedFileName) {
                            i = j
                            break
                        }
                    }
                    let fileURL = FileHandler.fetchAllReplays()[i]
                    print("!! - - - - recorded done - file url = = = = = = \(fileURL)")
                    self.outputURL = fileURL
                    self.delegate?.RecordingDidFinish(url: fileURL)
                }
            }
        }
    }
    
    private func setUpMP4CaptureToAssetWriting(fileName : String) {
        let fileURL = URL(fileURLWithPath: FileHandler.filePath(fileName))
        do {
            try assetWriter = AVAssetWriter(outputURL: fileURL, fileType: .mp4)
        } catch {
            print("!! - fail set up MP4 : \(error)")
        }
        guard let safeAssetWriter = assetWriter,
        let safeVideoInput = setUpVideoInput(),
        let safeAudioInput = setUpAudioInput() else {
            print("!! - failed to set up assetWriter / video / audio inputs")
            return
        }
        safeAssetWriter.add(safeVideoInput)
        safeAssetWriter.add(safeAudioInput)
    }
    
    private func setUpVideoInput() -> AVAssetWriterInput? {
        let videoOutputSettings : [String : Any] = [
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoWidthKey : closestInt(Int(UIScreen.main.bounds.size.width), 16),
            AVVideoHeightKey : closestInt(Int(UIScreen.main.bounds.size.height), 16)
        ]
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)
        guard let safeVideoInput = videoInput else {
            return nil
        }
        safeVideoInput.expectsMediaDataInRealTime = true
        return safeVideoInput
    }
    
    private func setUpAudioInput() -> AVAssetWriterInput? {
        let audioOutputSettings : [String : Any] = [
            AVFormatIDKey : kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey : 1,
            AVSampleRateKey : 44100.00
        ]
        audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioOutputSettings)
        guard let safeAudioInput = audioInput else {
            return nil
        }
        safeAudioInput.expectsMediaDataInRealTime = true
        return safeAudioInput
    }
    
    private func closestInt(_ a : Int, _ b : Int) -> Int {
        let c = a % b
        let x = a - c
        let y = a + b - c
        return a - x < y - a ? x : y
    }
}

extension Recorder : RPScreenRecorderDelegate {
    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
        //
    }
    
    func screenRecorder(_ screenRecorder: RPScreenRecorder, didStopRecordingWith previewViewController: RPPreviewViewController?, error: Error?) {
        //
    }
}
