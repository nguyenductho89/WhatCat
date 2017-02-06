//
//  DataService.swift
//  BotAge
//
//  Created by NGUYEN DUC THO on 11/15/16.
//  Copyright © 2016 vinicorp.com.vn. All rights reserved.
//

import UIKit
import Alamofire

let WATSON_API_KEY = "8c005343baecaa5f2bb4efc35270dbd9238b7303"
let VERSION = "2016-05-20"
let ImageResizeRation = 4
class DataService: NSObject {
    class var sharedInstance: DataService {
        struct Singleton {
            static let instance = DataService()
        }
        return Singleton.instance
    }
    func estimateAgeFromImage(image:UIImage, isSelfie :Bool, completion: @escaping (_ imageResult: NSMutableArray, _ result: Bool)->()) {
        var imageResultObj = ImageResult()
        let urlDetectFace =  String(format: "https://gateway-a.watsonplatform.net/visual-recognition/api/v3/detect_faces?api_key=%@&version=%@",WATSON_API_KEY,VERSION)
        print("Start upload image")
        var imageUploaded = image
        if isSelfie {
            imageUploaded = self.resizeImage(image: image, targetSize: CGSize(width: image.size.width/CGFloat(ImageResizeRation), height: image.size.height/CGFloat(ImageResizeRation)))
        }
        var imageSize: Int = UIImageJPEGRepresentation(imageUploaded,0.8)!.count/1024
        print(imageSize)

        Alamofire.upload(UIImageJPEGRepresentation(imageUploaded,0.9)!, to: urlDetectFace).uploadProgress {
            progress in // main queue by default
            print("Upload Progress: \(progress.fractionCompleted)")
            }.responseJSON(completionHandler: { (response) in
            let listImages = NSMutableArray()
            if response.result.isSuccess {
                print("Receive result")
                let result =  response.result.value as! NSDictionary
                print(result)
                let numberOfPeople = ((((result["images"] as! NSArray)[0] as! NSDictionary)["faces"] as! NSArray).count)
                print("Number of people : %d",numberOfPeople)
                if numberOfPeople > 0 {
                    let facesDictionary = (result["images"] as! NSArray)[0] as! NSDictionary
                    for i in 0...(numberOfPeople - 1) {
                        var max = 0
                        let ageDict = ((facesDictionary["faces"] as! NSArray)[i] as! NSDictionary)["age"] as!NSDictionary
                        
                        if  ageDict["max"] != nil {
                            max = ageDict["max"] as! Int
                        }
                        
                        var min = 0
                        if ageDict["min"] != nil {
                            min = ageDict["min"] as! Int
                        }
                        
                        let gender = (((facesDictionary["faces"] as! NSArray)[i] as! NSDictionary)["gender"] as!NSDictionary)["gender"] as! String
                        let top = (((facesDictionary["faces"] as! NSArray)[i] as! NSDictionary)["face_location"] as!NSDictionary)["top"] as! Int
                        let left = (((facesDictionary["faces"] as! NSArray)[i] as! NSDictionary)["face_location"] as!NSDictionary)["left"] as! Int
                        let height = (((facesDictionary["faces"] as! NSArray)[i] as! NSDictionary)["face_location"] as!NSDictionary)["height"] as! Int
                        let width = (((facesDictionary["faces"] as! NSArray)[i] as! NSDictionary)["face_location"] as!NSDictionary)["width"] as! Int
                        if max == 0 {
                            imageResultObj.age = min
                        }else if min == 0 {
                            imageResultObj.age = max
                        }else {
                            imageResultObj.age = (max + min)/2
                        }
                        
                        
                        if gender == "MALE" {
                            imageResultObj.isMan = true
                        }else{
                            imageResultObj.isMan = false
                        }
                        if isSelfie{
                            imageResultObj.top = top*ImageResizeRation
                            imageResultObj.left = left*ImageResizeRation
                            imageResultObj.height = height*ImageResizeRation
                            imageResultObj.width = width*ImageResizeRation
                        }else{
                        imageResultObj.top = top
                        imageResultObj.left = left
                        imageResultObj.height = height
                        imageResultObj.width = width
                        }
                        print(imageResultObj)
                        listImages.add(imageResultObj)
                        
                    }
                    completion(listImages,true)
                }else{
                completion(listImages,true)
                }

            }
            if response.result.isFailure {
                completion(listImages, false)
            }
        })

    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width:size.width * heightRatio, height:size.height * heightRatio)
        } else {
            newSize = CGSize(width:size.width * widthRatio,  height:size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    

    
    // import Alamofire
    func uploadWithAlamofire(image:UIImage, completion: @escaping (_ catArray: [CatResults]?, _ result: Bool)->()){
        var resultsArray = [CatResults]()

       // let image = UIImage(named: "cat.jpg")!
        
        // define parameters
//        let parameters = [
//            "hometown": "yalikavak",
//            "living": "istanbul"
//        ]
        
        Alamofire.upload(multipartFormData: { multipartFormData in
            if let imageData = UIImageJPEGRepresentation(image, 1) {
                multipartFormData.append(imageData, withName: "image", fileName: "file.png", mimeType: "image/png")
            }
            //add parameters
//            for (key, value) in parameters {
//                multipartFormData.append((value.data(using: .utf8))!, withName: key)
//            }
    }, to: "http://whatcat.ap.mextractr.net/api_query", method: .post, headers: ["Authorization": "Basic bWljcm8tZGV2OlA1czBsUEBzNQ=="],
                encodingCompletion: { encodingResult in
                    switch encodingResult {
                    case .success(let upload, _, _):
                        upload.responseJSON(completionHandler: { (jsonResponse) in
                                let results =  JSON(data: jsonResponse.data!)
                            
                            for (_,subJson):(String, JSON) in results {
                                let newCat = CatResults()
                                
                                newCat.nameType = subJson[0].string!
                               let accuracyPercent = self.roundToPlaces(value:100*Double(subJson[1].number! ), places: 2)
                               newCat.accuracyPercent = String(describing: accuracyPercent)
                                if accuracyPercent > 0 {
                                resultsArray.append(newCat)
                                }
                            }
                            print(resultsArray)
                            completion(resultsArray,true)
                            
                        })
                    case .failure(let encodingError):
                        print("error:\(encodingError)")
                        completion(nil,false)
                    }
        })
    }
    func roundToPlaces(value:Double, places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(value * divisor) / divisor
    }
}
