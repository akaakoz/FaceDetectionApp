//
//  ContentView.swift
//  FaceDetectionApp
//
//  Created by Akiya Ozawa on R 3/10/02.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    let videoCapture = VideoCapture()
        @State var image: UIImage? = nil
        var body: some View {
            if videoCapture.isSmiling == true {
                Text("Smiling 😄")
            } else if videoCapture.isSmiling == false {
                Text("Normal 🙁")
            } else {
                Text("")
            }
            VStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
                HStack {
                    Button("Start") {
                        videoCapture.run { sampleBuffer in
                            if let convertImage = UIImageFromSampleBuffer(sampleBuffer) {
                                DispatchQueue.main.async {
                                    self.image = convertImage
                                }
                            }
                        }
                    }
                    Button("Stop") {
                        videoCapture.stop()
                    }
                }
                .font(.largeTitle)
            }
        }

        func UIImageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
            if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
                let context = CIContext()
                if let image = context.createCGImage(ciImage, from: imageRect) {
                    return UIImage(cgImage: image)
                }
            }
            return nil
        }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
