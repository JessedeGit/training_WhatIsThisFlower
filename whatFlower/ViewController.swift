//
//  ViewController.swift
//  whatFlower
//
//  Created by applelee on 23/1/19.
//  Copyright © 2019 NewHope. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var textView: UITextView!
    let imagePickerController = UIImagePickerController()
    var flowerName : String = ""
    let wikipediaURl = "https://en.wikipedia.org/w/api.php?"
    
    lazy var parameters: [String:String] = [
        "format" : "json",
        "action" : "query",
        "prop" : "extracts|pageimages",
        "exintro" : "",
        "explaintext" : "",
        "titles" : flowerName,
        "indexpageids": "",
        "redirects" : "1",
        "pithumbsize": "500",
        ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = false
        imagePickerController.delegate = self
        
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
//            imageView.image = selectedImage
            let ciImage = CIImage(image: selectedImage)
            detect(ciImage: ciImage!)
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func detect(ciImage: CIImage){
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {fatalError("Creating Vision Model Error!")}
        
        let request = VNCoreMLRequest(model: model, completionHandler: {
            [weak self] request, error in
            self?.processClassification(for: request, error: error)
        })
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage)
            do {
                try handler.perform([request])
            } catch{
                print(error)
            }
        }
    }
    
    func processClassification(for request: VNRequest, error: Error?){
        DispatchQueue.main.async {
            guard let results = request.results as? [VNClassificationObservation] else
            {fatalError("unexpected result type from VNCoreMLRequest!")}
            if let flowerNameLocal = results.first?.identifier{
                self.navigationItem.title = "\(flowerNameLocal.capitalized)"
                self.flowerName = flowerNameLocal
                self.queryWiki(flowerName: self.flowerName)
            }
        }
    }
    
    func queryWiki(flowerName: String?){
        if let _ = flowerName{
            Alamofire.request(getQueryAddress()).responseJSON { (response) in
                if let value = try? JSON(data: response.data!) {
                    let id = value["query"]["pageids"][0]
                    let description = value["query"]["pages"][id.description]["extract"]
                    let url = value["query"]["pages"][id.description]["thumbnail"]["source"].stringValue
                    print(url)
                    self.imageView.sd_setImage(with: URL(string: url), completed: nil)
                    self.textView.text = description.stringValue
                }
            }
        }
    }
    
    func getQueryAddress() -> String{
        var result = wikipediaURl
        flowerName = flowerName.replacingOccurrences(of: " ", with: "%20")
        for para in parameters{
            result = result + para.key + "=" + para.value + "&"
        }
        return String(result[..<result.index(before: result.endIndex)])
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePickerController, animated: true, completion: nil)
    }
}

