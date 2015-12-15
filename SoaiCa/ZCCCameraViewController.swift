//
//  ZCCCameraViewController.swift
//  SoaiCa
//
//  Created by Zoom NGUYEN on 12/10/15.
//  Copyright © 2015 Zoom NGUYEN. All rights reserved.
//

import UIKit
import ImageIO

class ZCCCameraViewController: UIViewController,UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet var imageView: UIImageView!
    
    lazy var context: CIContext = {
        return CIContext(options: nil)
    }()

    var imagePicker: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func detectFace(image:UIImage) {
        
        
        imageView.image = image
        
        let inputImage = CIImage(image: imageView.image!)!
        
        let detector = CIDetector(ofType: CIDetectorTypeFace,
            context: context,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        
        var faceFeatures: [CIFaceFeature]!
        if let orientation: AnyObject = inputImage.properties[kCGImagePropertyOrientation as String] {
            faceFeatures = detector.featuresInImage(inputImage, options: [CIDetectorImageOrientation: orientation]) as! [CIFaceFeature]
        } else {
            faceFeatures = detector.featuresInImage(inputImage)as! [CIFaceFeature]
        }
        
        print(faceFeatures)
        
        // 1.
        let inputImageSize = inputImage.extent.size
        var transform = CGAffineTransformIdentity
        transform = CGAffineTransformScale(transform, 1, -1)
        transform = CGAffineTransformTranslate(transform, 0, -inputImageSize.height)
        
        for faceFeature in faceFeatures {
            var faceViewBounds = CGRectApplyAffineTransform(faceFeature.bounds, transform)
            
            // 2.
            let scale = min(imageView.bounds.size.width / inputImageSize.width,
                imageView.bounds.size.height / inputImageSize.height)
            let offsetX = (imageView.bounds.size.width - inputImageSize.width * scale) / 2
            let offsetY = (imageView.bounds.size.height - inputImageSize.height * scale) / 2
            
            faceViewBounds = CGRectApplyAffineTransform(faceViewBounds, CGAffineTransformMakeScale(scale, scale))
            faceViewBounds.origin.x += offsetX
            faceViewBounds.origin.y += offsetY
            
            let faceView = UIView(frame: faceViewBounds)
            faceView.layer.borderColor = UIColor.orangeColor().CGColor
            faceView.layer.borderWidth = 2
            
            imageView.addSubview(faceView)
        }

        pixellated(image)
    }
    
    func pixellated(image:UIImage) {
        // 1.
        let filter = CIFilter(name: "CIPixellate")!
        print(filter.attributes)
        let inputImage = CIImage(image: image)!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        // filter.setValue(max(inputImage.extent.size.width, inputImage.extent.size.height) / 60, forKey: kCIInputScaleKey)
        let fullPixellatedImage = filter.outputImage
        // let cgImage = context.createCGImage(fullPixellatedImage, fromRect: fullPixellatedImage.extent)
        // imageView.image = UIImage(CGImage: cgImage)
        // 2.
        let detector = CIDetector(ofType: CIDetectorTypeFace,
            context: context,
            options: nil)
        let faceFeatures = detector.featuresInImage(inputImage)
        // 3.
        var maskImage: CIImage!
        let scale = min(imageView.bounds.size.width / inputImage.extent.size.width,
            imageView.bounds.size.height / inputImage.extent.size.height)
        for faceFeature in faceFeatures {
            print(faceFeature.bounds)
            // 4.
            let centerX = faceFeature.bounds.origin.x + faceFeature.bounds.size.width / 2
            let centerY = faceFeature.bounds.origin.y + faceFeature.bounds.size.height / 2
            let radius = min(faceFeature.bounds.size.width, faceFeature.bounds.size.height) * scale
            let radialGradient = CIFilter(name: "CIRadialGradient",
                withInputParameters: [
                    "inputRadius0" : radius,
                    "inputRadius1" : radius + 1,
                    "inputColor0" : CIColor(red: 0, green: 1, blue: 0, alpha: 1),
                    "inputColor1" : CIColor(red: 0, green: 0, blue: 0, alpha: 0),
                    kCIInputCenterKey : CIVector(x: centerX, y: centerY)
                ])!
            
            print(radialGradient.attributes)
            // 5.
            let radialGradientOutputImage = radialGradient.outputImage!.imageByCroppingToRect(inputImage.extent)
            if maskImage == nil {
                maskImage = radialGradientOutputImage
            } else {
                print(radialGradientOutputImage)
                maskImage = CIFilter(name: "CISourceOverCompositing",
                    withInputParameters: [
                        kCIInputImageKey : radialGradientOutputImage,
                        kCIInputBackgroundImageKey : maskImage
                    ])!.outputImage
            }
            print(maskImage.extent)
        }
        // 6.
        let blendFilter = CIFilter(name: "CIBlendWithMask")!
        blendFilter.setValue(fullPixellatedImage, forKey: kCIInputImageKey)
        blendFilter.setValue(inputImage, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(maskImage, forKey: kCIInputMaskImageKey)
        // 7.
        let blendOutputImage = blendFilter.outputImage!
        let blendCGImage = context.createCGImage(blendOutputImage, fromRect: blendOutputImage.extent)
        imageView.image = UIImage(CGImage: blendCGImage)
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func btnTakePhotoTapped(sender: AnyObject) {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .PhotoLibrary
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
       
        imagePicker.dismissViewControllerAnimated(true) { () -> Void in
            
        }
        self.detectFace(image)
    }
    
}
