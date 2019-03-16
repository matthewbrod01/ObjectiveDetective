//
//  CameraViewController.swift
//  Objective Detective
//
//  Created by Matthew Rodriguez on 2/19/19.
//  Copyright © 2019 Matthew Rodriguez. All rights reserved.
//

import UIKit
import AVKit
import Vision // for object detection

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var myLabel = UILabel(frame: CGRect(x: 0, y: 686, width: 414, height: 50))
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Start the camera
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue")) // monitor frames from video for output
        captureSession.addOutput(dataOutput)
        
        let label = myLabel
        label.textAlignment = .center
        label.text = ""
        myLabel = label
        self.view.addSubview(myLabel)
        
        // responsible for analyzing images (through cgImage)
//        VNImageRequestHandler(cgImage: <#T##CGImage#>, options: [:]).perform(<#T##requests: [VNRequest]##[VNRequest]#>)
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // called every time the camera is able to capture a frame
        
//        print("Camera captured a new frame: ", Date())
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }
        let request = VNCoreMLRequest(model: model) { (finishedReq, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
//                print(finishedReq.results)
                guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
                guard let firstObservation = results.first else { return }
                DispatchQueue.main.sync {
                    self.myLabel.text = "\(firstObservation.identifier): \(firstObservation.confidence)"
                }
                //print(firstObservation.identifier, firstObservation.confidence)
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}
