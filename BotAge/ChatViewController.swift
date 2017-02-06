//
//  ChatViewController.swift
//  SwiftExample
//
//  Created by Nguyen Duc Tho on 5/11/16.
//  Copyright © 2016 vinicorp.com.vn . All rights reserved.
//

import UIKit
import JSQMessagesViewController
import Alamofire
import MBProgressHUD
let clientID : String = "Client"
let botID : String = ""
var isSelfie = true
let MESSAGES_NO_LIMIT = 30
struct FaceWindow {
    var top : Int = 0
    var left : Int = 0
    var width : Int = 0
    var height : Int = 0
    var age : Int = 0
    var isMan = false
}
struct ImageResult {
    var top : Int = 0
    var left : Int = 0
    var height : Int = 0
    var width : Int = 0
    var age = 0
    var isMan = false
    
}
class ChatViewController: JSQMessagesViewController, UIActionSheetDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    var messages = [JSQMessage]()
    var imageResult = ImageResult()
    //var conversation: Conversation?
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.lightGray)
    var listWindowFaces = NSMutableArray()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.topItem?.title  = "What Cat BOT"
        let btnClear = UIBarButtonItem(title: "クリア", style: .plain, target: self, action: #selector(clearMessages))//UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(clearMessages))//[[UIBarButtonItem initWithTitle:@"Show" style:UIBarButtonItemStylePlain target:self action:@selector(refreshPropertyList:)];
        self.navigationItem.rightBarButtonItem = btnClear
        //btnClear.title = "Clear all the messages"
        self.inputToolbar.contentView.rightBarButtonItem = nil
        let welcomMessage = JSQMessage.init(senderId: botID, senderDisplayName: botID, date: Date(), text: "Welcome to What Cat BOT!")
        self.messages.append(welcomMessage!)
        // This is how you remove Avatars from the messagesView
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 30, height: 30)
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = .zero//CGSize(width: 50, height: 50)
        
        // This is a beta feature that mostly works but to make things more stable I have diabled it.
        collectionView?.collectionViewLayout.springinessEnabled = false
        
        //Set the SenderId  to the current User
        // Anywhere that client is used you should replace with you currentUserVariable
        senderId = clientID
        senderDisplayName = "ME"
        //senderDisplayName = conversation?.firstName ?? conversation?.preferredName ?? conversation?.lastName ?? ""
        automaticallyScrollsToMostRecentMessage = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let  messageCount = self.messages.count
        if messageCount > MESSAGES_NO_LIMIT {
            
            let alertController = UIAlertController(title: "メモリ不足", message: "消費メモリが大きくなっています。クリアボタンでメッセージを削除し、使用メモリを確保してください。", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
            })
            alertController.addAction(defaultAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    override func didPressAccessoryButton(_ sender: UIButton!) {
        let imgPicker = UIImagePickerController()
        imgPicker.delegate = self
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "フォトライブラリ", style: .default, handler: { (UIAlertAction) in
            imgPicker.sourceType = .photoLibrary
            isSelfie = false
            self.present(imgPicker, animated: true, completion: nil)
        }))

        actionSheet.addAction(UIAlertAction(title: "写真を撮る", style: .default, handler: { (UIAlertAction) in
            imgPicker.sourceType = .camera
            isSelfie = true
            self.present(imgPicker, animated: true, completion: nil)
        }))
        self.present(actionSheet, animated: false, completion: nil)
        
    }
    //# MARK: - Collection View
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let date = NSDate()
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        let dateString = dateFormatter.string(from: date as Date)
        if indexPath.row % 5 == 0{
            return NSAttributedString(string: dateString)
        }else{
            return nil
        }
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return 30
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData!{
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        return messages[indexPath.item].senderId == clientID ? outgoingBubble : incomingBubble
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        switch message.senderId {
        case clientID:
            return NSAttributedString(string: "")
        default:
            guard let senderDisplayName = message.senderDisplayName else {
                assertionFailure()
                return nil
            }
            return NSAttributedString(string: senderDisplayName)
            
        }
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let avatarImage = UIImage(named: "appIcon.jpg")
        //avatarImage = JSQMessagesAvatarImageFactory.circularAvatarImage(avatarImage, withDiameter: 15)
        let avatar = JSQMessagesAvatarImage(avatarImage:avatarImage, highlightedImage: avatarImage, placeholderImage: avatarImage)
        return avatar
    }
    //# MARK: - UIImagePicker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.addPhotoToMessageList(image: pickedImage, senderId: clientID, displayName: "1234",isOutgoing: true)
           // sendImageToServer(image: pickedImage,isSelfie:isSelfie)
            sendCatImageToServer(image: pickedImage)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func addPhotoToMessageList(image:UIImage,senderId:String,displayName:String,isOutgoing: Bool){
        let photo = JSQPhotoMediaItem(image: image)!
        photo.appliesMediaViewMaskAsOutgoing = isOutgoing;
        self.messages.append(JSQMessage(senderId: senderId, displayName: displayName, media: photo));
        self.finishReceivingMessage(animated: true)
        self.collectionView?.reloadData()
    }
    func sendCatImageToServer(image:UIImage) {
        let loadingNotification =  MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.label.text = "Analysing..."
        DispatchQueue.global(qos: .background).async {
            DataService.sharedInstance.uploadWithAlamofire(image: image, completion: { (catArray, success) in
                if success {
                    if (catArray!.count) > 0 {
                        //                                        self.listWindowFaces.removeAllObjects()
                        var responseMessage = ""
                        for item in catArray! {
                            responseMessage.append(item.nameType + " " + item.accuracyPercent + "%\n")
                        }
                        let endIndex = responseMessage.index(responseMessage.endIndex, offsetBy: -2)
                        responseMessage = responseMessage.substring(to: endIndex)
                        DispatchQueue.main.async {
                            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                            let message = JSQMessage.init(senderId: botID, senderDisplayName: botID, date: Date(), text: responseMessage)
                            self.messages.append(message!)
                            self.reloadDataAndSrcollToBottom()
                        }
                    }else{
                        DispatchQueue.main.async {
                            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                            let alertController = UIAlertController(title: nil, message: "認識出来ませんでした。", preferredStyle: .alert)
                            
                            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alertController.addAction(defaultAction)
                            
                            self.present(alertController, animated: true, completion: nil)
                        }
                        
                    }
                }else{
                    DispatchQueue.main.async {
                        MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                        let alertController = UIAlertController(title: nil, message: "インターネットに接続していることを確認してください。", preferredStyle: .alert)
                        
                        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertController.addAction(defaultAction)
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
                
            })

            
        }
        
    }
    
    
    func sendImageToServer(image:UIImage,isSelfie:Bool) {
        let loadingNotification =  MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.label.text = "Analysing..."
        DispatchQueue.global(qos: .background).async {
            DataService.sharedInstance.estimateAgeFromImage(image: image,isSelfie:isSelfie, completion: { (listImages, success) in
                if success {
                    if listImages.count > 0 {
                        self.listWindowFaces.removeAllObjects()
                        for item in listImages {
                            var faceWindow = FaceWindow()
                            faceWindow.top = (item as! ImageResult).top
                            faceWindow.left = (item as! ImageResult).left
                            faceWindow.width = (item as! ImageResult).width
                            faceWindow.height = (item as! ImageResult).height
                            faceWindow.age = (item as! ImageResult).age
                            faceWindow.isMan = (item as! ImageResult).isMan
                            self.listWindowFaces.add(faceWindow)
                        }
                        DispatchQueue.main.async {
                            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                            var finalImage = self.addWindowOnFaces(originalImage: image, listWindow: self.listWindowFaces)
                            self.addPhotoToMessageList(image: finalImage, senderId: botID, displayName: botID, isOutgoing: false)
                        }
                    }else{
                        DispatchQueue.main.async {
                            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                            let alertController = UIAlertController(title: nil, message: "認識出来ませんでした。", preferredStyle: .alert)
                            
                            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alertController.addAction(defaultAction)
                            
                            self.present(alertController, animated: true, completion: nil)
                        }
                        
                    }
                }else{
                    DispatchQueue.main.async {
                        MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                        let alertController = UIAlertController(title: nil, message: "インターネットに接続していることを確認してください。", preferredStyle: .alert)
                        
                        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertController.addAction(defaultAction)
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            })
            
        }
        
    }
    
    func textToImage(drawText text: NSString, inImage image: UIImage, atPoint point: CGPoint) -> UIImage {
        let textColor = UIColor.red
        let textFont = UIFont(name: "Helvetica Bold", size: 80)!
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)
        
        let textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
            ] as [String : Any]
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        
        let rect = CGRect(origin: point, size: image.size)
        text.draw(in: rect, withAttributes: textFontAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    
    func addWindowOnFaces(originalImage:UIImage, listWindow:NSMutableArray) -> UIImage{
        UIGraphicsBeginImageContext(originalImage.size);
        let textColor = UIColor.red
        var textFont = UIFont(name: "Helvetica Bold", size: 80)!
        
        // Pass 1: Draw the original image as the background
        originalImage.draw(at: CGPoint.zero)
        // Pass 2: Draw the line on top of original image
        let context = UIGraphicsGetCurrentContext();
        context!.setLineWidth(5.0);
        for faceWindowItem in listWindow {
            context!.move(to: CGPoint.init(x: (faceWindowItem as!
                FaceWindow).left, y: (faceWindowItem as! FaceWindow).top))
            // bottom left
            context!.addLine(to: CGPoint.init(x: (faceWindowItem as! FaceWindow).left, y: (faceWindowItem as! FaceWindow).top + (faceWindowItem as! FaceWindow).height))
            
            // bottom right
            context!.addLine(to: CGPoint.init(x: (faceWindowItem as! FaceWindow).left + (faceWindowItem as! FaceWindow).width, y: (faceWindowItem as! FaceWindow).top + (faceWindowItem as! FaceWindow).height))
            
            // top right
            
            context!.addLine(to: CGPoint.init(x: (faceWindowItem as! FaceWindow).left + (faceWindowItem as! FaceWindow).width, y: (faceWindowItem as! FaceWindow).top))
            
            // top left
            
            context!.addLine(to: CGPoint.init(x: (faceWindowItem as! FaceWindow).left, y: (faceWindowItem as! FaceWindow).top))
            
            /* Add age */
            // get 1/5 size of faceWindow
            let iconGenderSize = Int(Float((faceWindowItem as! FaceWindow).height)/4.0)
            let rect = CGRect(origin: CGPoint.init(x: (faceWindowItem as! FaceWindow).left + iconGenderSize  , y: (faceWindowItem as! FaceWindow).top ), size: originalImage.size)
            let ageString = String((faceWindowItem as! FaceWindow).age)
            textFont = UIFont(name: "Helvetica Bold", size: CGFloat(iconGenderSize))!
            let textFontAttributes = [
                NSFontAttributeName: textFont,
                NSForegroundColorAttributeName: textColor,
                ] as [String : Any]
            ageString.draw(in: rect, withAttributes: textFontAttributes)
            
            /*Add gender*/
            
            var topImage = UIImage()
            if (faceWindowItem as! FaceWindow).isMan {
                topImage = UIImage(named: "man.png")!
            }else{
                topImage = UIImage(named: "woman.png")!
            }
            
            let newSize = CGSize(width: iconGenderSize, height: iconGenderSize) // set this to what you need
            topImage.draw(in: CGRect(origin: CGPoint.init(x: (faceWindowItem as! FaceWindow).left  , y: (faceWindowItem as! FaceWindow).top), size: newSize))
            
        }
        context!.setStrokeColor(UIColor.white.cgColor)
        context!.strokePath();
        
        // Create new image
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        
        // Tidy up
        UIGraphicsEndImageContext();
        return newImage!
    }
    func clearMessages(){
        self.messages.removeAll();
        let welcomMessage = JSQMessage.init(senderId: botID, senderDisplayName: botID, date: Date(), text: "Welcome to What Cat BOT!")
        self.messages.append(welcomMessage!)
        self.collectionView?.reloadData()
        
    }
    func reloadDataAndSrcollToBottom(){
        self.collectionView?.reloadData()
        let item = self.collectionView(self.collectionView!, numberOfItemsInSection: 0) - 1
        let lastItemIndex = NSIndexPath(item: item, section: 0)
        self.collectionView?.scrollToItem(at: lastItemIndex as IndexPath, at: UICollectionViewScrollPosition.top, animated: true)
    }
}
