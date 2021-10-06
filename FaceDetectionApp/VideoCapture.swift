//
//  AVFoundationVM.swift
//  FaceDetectionApp
//
//  Created by Akiya Ozawa on R 3/10/02.
//

import UIKit
import AVFoundation
import Firebase

class VideoCapture: NSObject {
    private let captureSession = AVCaptureSession()
    var handler: ((CMSampleBuffer) -> Void)?
    var isSmiling: Bool?
    private lazy var vision = Vision.vision()
    
    lazy var options: VisionFaceDetectorOptions = {
        let options = VisionFaceDetectorOptions()
        options.performanceMode = .accurate
        options.landmarkMode = .all
        options.classificationMode = .all
        return options
    }()
    
    override init() {
        super.init()
        setup()
    }
    
    func setup() {
            captureSession.beginConfiguration()
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            guard
                let deviceInput = try? AVCaptureDeviceInput(device: device!),
                captureSession.canAddInput(deviceInput)
                else { return }
            captureSession.addInput(deviceInput)

            let videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "mydispatchqueue"))
            videoDataOutput.alwaysDiscardsLateVideoFrames = true

            guard captureSession.canAddOutput(videoDataOutput) else { return }
            captureSession.addOutput(videoDataOutput)

            for connection in videoDataOutput.connections {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }

            captureSession.commitConfiguration()
        }

        func run(_ handler: @escaping (CMSampleBuffer) -> Void)  {
            if !captureSession.isRunning {
                self.handler = handler
                captureSession.startRunning()
            }
        }

        func stop() {
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
    }

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let handler = handler {
            
            let faceDetector = vision.faceDetector(options: options)
            let image = VisionImage(buffer: sampleBuffer)
            faceDetector.process(image) { faces, error in
                guard error == nil, let faces = faces, !faces.isEmpty else {
                    return
                }
                
                print("faces", faces)
                
                for face in faces {
                    if face.hasSmilingProbability {
                        let smileProb = face.smilingProbability
                        print("smileProb", smileProb)
                        if smileProb >= 0.6 {
                            self.isSmiling = true
                        } else {
                            self.isSmiling = false
                        }
                        
                    }
                }
            }
            
            handler(sampleBuffer)
        }
    }
}
