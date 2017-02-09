//
//  AppDelegate.h
//  youtube
//
//  Created by Akira on 11/20/16.
//  Copyright © 2016 Akira. All rights reserved.

import UIKit
import AVKit
import AVFoundation
import Photos
import Alamofire
import YoutubeSourceParserKit
import youtube_ios_player_helper
import MBProgressHUD
import AVKit
import Photos
import DKImagePickerController

import MobileCoreServices
import AssetsLibrary

class PlayVideoViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    @IBOutlet weak var playerView: YTPlayerView!
    @IBOutlet weak var Video_Editor: UIButton!

    let Your_host_youtube_str = "https://www.youtube.com/watch?v="
    
    var pickerController: DKImagePickerController!
    var camera_test:DKCamera!
    
    var videoID: String?
    var VideoUrl: String!
    var assets: [DKAsset]?
    var originalURL: NSURL?

    override func viewDidLoad() {
        super.viewDidLoad()
        pickerController = DKImagePickerController()
        VideoUrl = Your_host_youtube_str + videoID!
        playerView.loadWithVideoId(videoID!)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        VideoUrl = Your_host_youtube_str + videoID!
        print(VideoUrl)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func Video_Editor_Creater(sender: AnyObject) {
        
      
        self.Normal_imagepickercontroller_set()

//            self.showImagePickerWithAssetType(.AllAssets, allowMultipleType: true, allowsLandscape: false, singleSelect: false)
        
    }
    
    func Normal_imagepickercontroller_set(){
        //*********************************************************
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .SavedPhotosAlbum
        imagePickerController.mediaTypes = [(kUTTypeMovie as String), (kUTTypeAVIMovie as String), (kUTTypeVideo as String), (kUTTypeMPEG4 as String)]
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = false
        self.presentViewController(imagePickerController, animated: true, completion: nil)
        //***************************************************************************

    }
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])   {
        print("test!!")
        picker.dismissViewControllerAnimated(true, completion: { _ in })
        
        let url = (info[UIImagePickerControllerMediaURL] as! NSURL)
        
        
        self.originalURL = url as NSURL
        self.performSegueWithIdentifier("TrimView", sender: nil)
    }
    
    func showImagePickerWithAssetType(assetType: DKImagePickerControllerAssetType,
                                      allowMultipleType: Bool,
                                      sourceType: DKImagePickerControllerSourceType = .Both,
                                      allowsLandscape: Bool,
                                      singleSelect: Bool) {
        
        let pickerController = DKImagePickerController()
        
        pickerController.assetType = .AllVideos
        pickerController.allowsLandscape = allowsLandscape
        pickerController.allowMultipleTypes = allowMultipleType
        pickerController.sourceType = sourceType
        pickerController.singleSelect = true
        
        
        
        pickerController.showsCancelButton = false
        
        // Clear all the selected assets if you used the picker controller as a single instance.
        pickerController.defaultSelectedAssets = nil
        
        pickerController.didSelectAssets = { [unowned self] (assets: [DKAsset]) in
            print("didSelectAssets")
            
//            self.assets = assets
//            let localVideoUrl : NSURL =
            
//            self.performSegueWithIdentifier("TrimView", sender: nil)
            //            if assets.count != 0 {
            //                self.performSegueWithIdentifier("MergeVCSegue", sender: nil)
            ////                showSimpleAlert("", message: "Asset count 0!", presentingController: self)
            //            }
        }
        
        if UI_USER_INTERFACE_IDIOM() == .Pad {
            pickerController.modalPresentationStyle = .FormSheet
        }
        
        self.presentViewController(pickerController, animated: true, completion: nil)
    }

    
    @IBAction func Camera_recording(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            
            
            print("captureVideoPressed and camera available.")
            
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType = .Camera;
            imagePicker.mediaTypes = [kUTTypeMovie as! String]
            imagePicker.videoMaximumDuration = 5
            imagePicker.allowsEditing = false
            
            imagePicker.showsCameraControls = true
            
            
            self.presentViewController(imagePicker, animated: true, completion: nil)
            
        }
            
        else {
            print("Camera not available.")
        }

        
        showSimpleAlert("", message: "please recod video", presentingController: self)
    }
    @IBAction func File_check(sender: AnyObject) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        self.presentViewController(picker, animated: true, completion: nil)
        
    }
    @IBAction func downloadbuttonclick(sender: AnyObject) {

        let Video_Str = VideoUrl
        let video_Url = NSURL(string:Video_Str);
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        
        Youtube.h264videosWithYoutubeURL(video_Url!) { (videoInfo, error) -> Void in
            if let videoURLString = videoInfo?["url"] as? String{
                self.downloadVideoAndSaveToAlbum(videoURLString)
            }else{
                dispatch_async(dispatch_get_main_queue(), { 
                    MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                    showSimpleAlert("", message: "Cannot download this video", presentingController: self)
                })
            }
        }
    }
    
    
    
    let DocumentFolderURL:NSURL = {
        let documentsDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        return documentsDirectory
    }()
    
    func downloadVideoAndSaveToAlbum(url:String){
        let pathComponent = videoID! + ".mp4"
        print(pathComponent)
        
        let documentsDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        let localFileUrl = documentsDirectory.URLByAppendingPathComponent(pathComponent)!
        
        if NSFileManager.defaultManager().fileExistsAtPath(localFileUrl.path!) {
            do{
                try NSFileManager.defaultManager().removeItemAtURL(localFileUrl)
            }catch _ as NSError {
                showSimpleAlert("", message: "Cannot save this video", presentingController: self)
                return
            }
            
        }
        
        Alamofire.download(.GET, url) { temporaryURL, response in
            return localFileUrl
            }.progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
            }.response { _, response, data, error in
                if let pathURL = localFileUrl as NSURL?{
                    
                    PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(pathURL)
                    }) { completed, error in
                        dispatch_async(dispatch_get_main_queue(), {
                            MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                            if completed{
                                print("Saved ok")
                                showSimpleAlert("", message: "Download OK", presentingController: self)
                            }else{
                                print("Error: \(error?.localizedDescription)")
                                showSimpleAlert("", message: "Cannot download this video", presentingController: self)
                            }
                        })
                    }

                }else{
                    print("Cannot download this video")
                    dispatch_async(dispatch_get_main_queue(), {
                        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                        showSimpleAlert("", message: "Cannot download this video", presentingController: self)
                    })
                }
            }
        }
    
        override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
            if segue.identifier == "MergeVCSegue" {
                if let destination = segue.destinationViewController as? MergeViewController {
                   destination.assets = assets
                }
            }
            
            else if segue.identifier == "TrimView" {
                let trimVC = segue.destinationViewController as! TrimViewController
                trimVC.get_VideoUrl = self.originalURL
            }
        }
}




















