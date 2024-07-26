//
//  ViewController.swift
//  V2
//
//  Created by Ahmed Amrou on 6/22/24.
//

import UIKit
import CropViewController


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var takePhotoButton: UIButton!
    @IBOutlet var selectPhotoButton: UIButton!
    @IBOutlet var textInCenter: UILabel!
    var finalBuffer: CVPixelBuffer?
    var imageClassification: MobileNetV2Output?
    var finalModel: MobileNetV2?
    override func viewDidLoad() {
        print("view loaded")
        super.viewDidLoad()
        let model = MobileNetV2()
        finalModel = model
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func didTapTakePhotoButton() {
        print("button tapped")
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    @IBAction func didTapSelectPhotoButton() {
        print("select photo button tapped")
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
        
    }
    
    func showCrop(image: UIImage) {
        let vc = CropViewController(croppingStyle: .default, image: image)
        vc.aspectRatioPreset = .presetSquare
        vc.aspectRatioLockEnabled = true
        vc.resetAspectRatioEnabled = false
        vc.doneButtonTitle = "Done"
        vc.cancelButtonTitle = "Back"
        vc.delegate = self
        present(vc, animated: true)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        cropViewController.dismiss(animated: true)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        print("did crop")
        let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 224, height: 224))
        cropViewController.dismiss(animated: true)
        finalBuffer = buffer(from: resizedImage)
        performImageClassification()
    }
    
    func buffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                self.showCrop(image: image)
            }
        }
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(origin: .zero, size: newSize)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func performImageClassification() {
        guard let model = finalModel else {
            print("Model is nil")
            return
        }
        
        guard let buffer = finalBuffer else {
            print("Buffer is nil")
            return
        }
        
        do {
            let startTime = Date()
            let output = try model.prediction(image: buffer)
            imageClassification = output
            let endTime = Date()
            let timeInterval = endTime.timeIntervalSince(startTime)
            print(timeInterval)
            print(output.classLabel)
            textInCenter.text = output.classLabel
            textInCenter.textColor = .black
            // Process your prediction output here
        } catch {
            print("Error making prediction: \(error.localizedDescription)")
        }
    }

}
