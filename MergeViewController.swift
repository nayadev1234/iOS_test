//
//  MergeViewController.swift
//  VideoProcessing
//
//  Created by Akira on 11/20/16.
//  Copyright © 2016 Akira. All rights reserved.

import UIKit
import AVFoundation
import DKImagePickerController
import AVKit
import AssetsLibrary
import MBProgressHUD
import MediaPlayer

let TIMESCALE = 30

class MergeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SelectMusicViewControllerDelegate{
    
    var assets: [DKAsset]?
    @IBOutlet var tableView: UITableView!
    @IBOutlet var btnMerge: UIButton!
    @IBOutlet var btnPreview: UIButton!
    @IBOutlet var btnSaveToGallery: UIButton!
    @IBOutlet var imageView: UIImageView!

    private var filePath: NSString!
    private var av_AssetList: [AVAsset]!
    private var assetTrackList: [AVAssetTrack]!
    private var assetTrackAudioList: [AVAssetTrack?]!
    private var timeDurations: [NSValue]!
    private var imageList: [UIImage]!
    
    private var imageAsset: AVAsset!
    private var audioAsset: AVAsset?
    
    private var indexOfVideo: Int!
    private var indexOfPhoto: Int!
    private var indexOfAsset: Int!
    
    var videoFilePath:String!
    var resultFilePath:String!
    
    let videoSettings = [
        AVVideoCodecKey: AVVideoCodecH264,
        AVVideoWidthKey: 640,
        AVVideoHeightKey: 480
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        indexOfVideo = 0
        indexOfPhoto = 0
        indexOfAsset = 0
        
        // Do any additional setup after loading the view.
        av_AssetList = [AVAsset]()
        imageList = [UIImage]()
        assetTrackList = [AVAssetTrack]()
        timeDurations = [NSValue]()
        assetTrackAudioList = [AVAssetTrack]()
        let pathForImage = NSBundle.mainBundle().pathForResource("StartVid", ofType: "mp4")
        
        self.imageAsset = AVAsset(URL: NSURL(fileURLWithPath: pathForImage!))
        let filePaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory
            , .UserDomainMask, true)
        filePath = filePaths[0] as NSString!
        videoFilePath = filePath.stringByAppendingString("/video_photo")
        resultFilePath = filePath.stringByAppendingString("/result.mov")
        
        btnPreview.hidden = true
        btnSaveToGallery.hidden = true
        
        self.getAVAssets()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
//        indexOfVideo = 0
//        indexOfPhoto = 0
//        indexOfAsset = 0
//        
//        // Do any additional setup after loading the view.
//        av_AssetList = [AVAsset]()
//        imageList = [UIImage]()
//        assetTrackList = [AVAssetTrack]()
//        timeDurations = [NSValue]()
//        assetTrackAudioList = [AVAssetTrack]()
//        let pathForImage = NSBundle.mainBundle().pathForResource("StartVid", ofType: "mp4")
//        
//        self.imageAsset = AVAsset(URL: NSURL(fileURLWithPath: pathForImage!))
//        let filePaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory
//            , .UserDomainMask, true)
//        filePath = filePaths[0] as NSString!
//        videoFilePath = filePath.stringByAppendingString("/video_photo")
//        resultFilePath = filePath.stringByAppendingString("/result.mov")
//        
//        
//        
//        self.getAVAssets()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SelectMusicSegue" {
            let vc = segue.destinationViewController as! SelectMusicViewController
            vc.delegate = self
        }
    }
    
    // MARK: Get AVAssets
    private func getAVAssets() {
        btnPreview.hidden = true
        btnSaveToGallery.hidden = true
        btnMerge?.backgroundColor = UIColor.greenColor()
        if let assets = assets {
            if indexOfAsset >= (assets.count) {
                return
            }
            
            if (assets[indexOfAsset].isVideo) {
                assets[indexOfAsset].fetchAVAssetWithCompleteBlock({ (avAsset, _) in
                    if let avasset = avAsset {
                        self.av_AssetList.append(avasset)
                        self.indexOfAsset = self.indexOfAsset + 1
                        self.getAVAssets()
                    }
                })
            } else {
                assets[indexOfAsset].fetchOriginalImage(true, completeBlock: { (image, _) in
                    self.imageList.append(image!)
                    self.indexOfAsset = self.indexOfAsset + 1
                    self.getAVAssets()
                })
            }
        }
    }

    // MARK: Button Action
    @IBAction func onClickedMergeButton(sender: UIButton?) {
        
        sender?.backgroundColor = UIColor.darkGrayColor()
        btnPreview.hidden = false
        btnSaveToGallery.hidden = false
        
        indexOfVideo = 0
        indexOfPhoto = 0
        
        self.makeAVAssetList()
        self.timeDurationMake()
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        self.mergeVideoAndPhoto()
    }
    
    @IBAction func onClickedPreviewButton(sender: UIButton?) {
        print(resultFilePath)
        let playerVC = AVPlayerViewController()
        let player = AVPlayer(URL: NSURL(fileURLWithPath: resultFilePath))
        playerVC.player = player
        self.presentViewController(playerVC,animated: true){
            player.play()
        }
    }
    
    @IBAction func onClickedSaveButton(sender: UIButton?) {
        
        let videoFileUrl = NSURL(fileURLWithPath: resultFilePath)
        print(videoFileUrl)
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        let library = ALAssetsLibrary()
        if library.videoAtPathIsCompatibleWithSavedPhotosAlbum(videoFileUrl) {
            library.writeVideoAtPathToSavedPhotosAlbum(videoFileUrl, completionBlock: { (assetUrl, error) in
                if let error = error {
                    print("Error====", error)
                    MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                    self.showAlertWith("Cannot Save videod!", title: "Error")
                } else {
                    print("Video Saved")
                    MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                    self.showAlertWith("Video Saved Successfully", title: "Success")
                }
            })
        }
    }
    
    // MARK: Merge Video and Photo
    func mergeVideoAndPhoto() {
        
        if indexOfVideo >= (assets?.count)! {
            self.mergeVideos()
            return
        }
        
        let composition = AVMutableComposition()
        let compositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        do {
            try compositionTrack.insertTimeRange(timeDurations[indexOfVideo].CMTimeRangeValue, ofTrack: assetTrackList[indexOfVideo], atTime: kCMTimeZero)
            if audioAsset == nil {
                if let audioTrack = assetTrackAudioList[indexOfVideo]{
                    let audioCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
                    try audioCompositionTrack.insertTimeRange(timeDurations[indexOfVideo].CMTimeRangeValue, ofTrack: audioTrack, atTime: kCMTimeZero)
                    compositionTrack.preferredTransform = assetTrackList[indexOfVideo].preferredTransform
                }
            }
            
        } catch {
            print("Cannot merge cvideos!")
        }
        
        var layerComposition: AVMutableVideoComposition? = nil
        
        if !(assets?[indexOfVideo].isVideo)! {
            
            var isVideoAssetPortrait = false
            let videoTransform = assetTrackList[indexOfVideo].preferredTransform
            var videoAssetOrientation = UIImageOrientation.Up
            if videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0
            {
                videoAssetOrientation = UIImageOrientation.Right
                isVideoAssetPortrait = true
            }
            if videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0
            {
                videoAssetOrientation = UIImageOrientation.Left
                isVideoAssetPortrait = true
            }
            if videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0
            {
                videoAssetOrientation = UIImageOrientation.Up
            }
            if videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0
            {
                videoAssetOrientation = UIImageOrientation.Down
            }
        
            let naturalSize = assetTrackList[indexOfVideo].naturalSize
        
            let insertImageLayer = CALayer()
            let backgroundLayer = CALayer()
            let parentLayer = CALayer()
            //parentLayer.contentsGravity = kCAGravityResizeAspect
            
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: naturalSize.width, height: naturalSize.height))
            imageView.image = imageList[indexOfPhoto]
            imageView.contentMode = UIViewContentMode.ScaleAspectFit
            
            if imageList[indexOfPhoto].imageOrientation == UIImageOrientation.Down {
                print("Image is sdfasdfasdf")
            } else if imageList[indexOfPhoto].imageOrientation == UIImageOrientation.Left || imageList[indexOfPhoto].imageOrientation == .Right {
                print("Image is portrait")
                imageView.contentMode = .ScaleToFill
                imageView.layer.transform = CATransform3DMakeRotation(CGFloat(Float(M_PI)), 0.0, 0.0, 1.0)
            }

            
            insertImageLayer.frame = CGRect(x: 0, y: 0, width: naturalSize.width, height: naturalSize.height)
            backgroundLayer.frame = CGRect(x: 0, y: 0, width: naturalSize.width, height: naturalSize.height)

            print("Video natureal size %f", insertImageLayer.frame.size)
            insertImageLayer.addSublayer(imageView.layer)
            insertImageLayer.contentsGravity = kCAGravityResizeAspect
            insertImageLayer.backgroundColor = UIColor.blackColor().CGColor
            
            indexOfPhoto = indexOfPhoto + 1
            
            parentLayer.addSublayer(backgroundLayer)
            parentLayer.addSublayer(insertImageLayer)
            
            layerComposition = AVMutableVideoComposition()
            layerComposition?.frameDuration = timeDurations[indexOfVideo].CMTimeRangeValue.duration
            layerComposition?.animationTool = AVVideoCompositionCoreAnimationTool.init(postProcessingAsVideoLayer: backgroundLayer, inLayer: parentLayer)
            
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = timeDurations[indexOfVideo].CMTimeRangeValue
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: assetTrackList[indexOfVideo])
    
            var forstAssetScaleToFitRatio = naturalSize.width / naturalSize.width
            
            if isVideoAssetPortrait {
                
                
//                forstAssetScaleToFitRatio = assetTrack.naturalSize.width / assetTrack.naturalSize.height
//                
//                let firstAssetScaleFactor = CGAffineTransformMakeScale(CGFloat(forstAssetScaleToFitRatio), CGFloat(forstAssetScaleToFitRatio))
                
                
                forstAssetScaleToFitRatio = naturalSize.width / naturalSize.height
                let firstAssetScaleFactor = CGAffineTransformMakeScale(CGFloat(forstAssetScaleToFitRatio), CGFloat(forstAssetScaleToFitRatio))
                 let concat = CGAffineTransformConcat(CGAffineTransformConcat(assetTrackList[indexOfVideo].preferredTransform, firstAssetScaleFactor), CGAffineTransformMakeTranslation(0, 0))
                 layerInstruction.setTransform(concat, atTime: kCMTimeZero)
//                layerInstruction.setTransform(CGAffineTransformConcat(assetTrackList[indexOfVideo].preferredTransform, firstAssetScaleFactor), atTime: kCMTimeZero)
            } else {
                
                let firstAssetScaleFactor = CGAffineTransformMakeScale(CGFloat(forstAssetScaleToFitRatio), CGFloat(forstAssetScaleToFitRatio))
                
//                layerInstruction.setTransform(CGAffineTransformConcat(assetTrackList[indexOfVideo].preferredTransform,(CGAffineTransformMakeTranslation(0, 0)), firstAssetScaleFactor), atTime: kCMTimeZero)
               
                
                let concat = CGAffineTransformConcat(CGAffineTransformConcat(assetTrackList[indexOfVideo].preferredTransform, firstAssetScaleFactor), CGAffineTransformMakeTranslation(0, 0))
                
                layerInstruction.setTransform(concat, atTime: kCMTimeZero)
            }

            
            instruction.layerInstructions = [layerInstruction]
            layerComposition?.instructions = [instruction]
            layerComposition?.renderSize = naturalSize
            
        }
        
        let videoFileUrl = NSURL(fileURLWithPath: String(format: "%@%d.mov", videoFilePath,indexOfVideo))
        print("video file url", videoFileUrl)
        if
            NSFileManager.defaultManager().fileExistsAtPath(String(format: "%@%d.mov", videoFilePath,indexOfVideo)) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(String(format: "%@%d.mov", videoFilePath,indexOfVideo))
            } catch {
                print("========== Error ===========")
                self.showAlertWith("Cannot merge videod(error file error)!", title: "Error")
            }
        }
        
        let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        assetExport?.outputFileType = AVFileTypeQuickTimeMovie
        assetExport?.outputURL = videoFileUrl
        assetExport?.videoComposition = layerComposition
        assetExport?.timeRange = timeDurations[indexOfVideo].CMTimeRangeValue
        assetExport?.exportAsynchronouslyWithCompletionHandler({
            if let assetExport = assetExport {
                switch assetExport.status {
                
                case .Failed:
                    print("------------ Error --------- : export hightlight files")
                    MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                    self.showAlertWith("Cannot merge videod(video =1 fial)!", title: "Error")
                    break
                case .Cancelled:
                    print("------------ Error --------- : export hightlight files")
                    MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                    self.showAlertWith("Cannot merge videod(origine)!", title: "Error")
                    break
                case .Completed:
                    print(self.indexOfVideo," Video making Success!!")
                    
//                    let library = ALAssetsLibrary()
//                                         if library.videoAtPathIsCompatibleWithSavedPhotosAlbum(videoFileUrl) {
//                                            library.writeVideoAtPathToSavedPhotosAlbum(videoFileUrl, completionBlock: { (assetUrl, error) in
//                                                if let error = error {
//                                                    print("Error====", error)
////                                                    MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
//                                                    self.showAlertWith("Cannot Save videod!", title: "Error")
//                                                } else {
//                                                    print("Video Saved")
////                                                    MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
//                                                   // self.showAlertWith("Video Saved Successfully", title: "Success")
//                                                }
//                                            })
//                                         }

                    self.indexOfVideo = self.indexOfVideo + 1
                    self.mergeVideoAndPhoto()
                    break
                default:
                    
                    break
                }
            }
        })
        
    }
    
    private func mergeVideos() {
        print(timeDurations)
        var assetTracks: [AVAsset] = [AVAsset]()
        //  2 Create video tracks for merge
        for i in 0 ... (assets?.count)! - 1 {
            let avAsset = AVAsset(URL: NSURL(fileURLWithPath: String(format: "%@%d.mov", videoFilePath, i)))
            assetTracks.append(avAsset)
        }

        print(assetTracks)

        let composition = AVMutableComposition()
        
        var arrayInstructions = [AVMutableVideoCompositionLayerInstruction]()

        let mainInstruction = AVMutableVideoCompositionInstruction()
        
        let haveManualAudio = audioAsset == nil ? false : true

        var duration = kCMTimeZero
        
           for i in 0 ... (assets?.count)! - 1 {
                let compositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
            let assetTrack = assetTracks[i].tracksWithMediaType(AVMediaTypeVideo)[0]
            
            do{
                try compositionTrack.insertTimeRange(timeDurations[i].CMTimeRangeValue, ofTrack: assetTrack, atTime: duration)
                
                if !haveManualAudio {//manual music add false
                    let audioAssetTrack: AVAssetTrack?
                    if assetTracks[i].tracksWithMediaType(AVMediaTypeAudio).count != 0 {
                        audioAssetTrack = assetTracks[i].tracksWithMediaType(AVMediaTypeAudio)[0]
                        let audioCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
                        try audioCompositionTrack.insertTimeRange(timeDurations[i].CMTimeRangeValue, ofTrack: audioAssetTrack!, atTime: duration)
                    } 
                }
                else{// manual music add true
                        let audioAssetTrack: AVAssetTrack?
                        if assetTracks[i].tracksWithMediaType(AVMediaTypeAudio).count != 0
                            {
                                audioAssetTrack = assetTracks[i].tracksWithMediaType(AVMediaTypeAudio)[0]
                                let audioCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
                                try audioCompositionTrack.insertTimeRange(timeDurations[i].CMTimeRangeValue, ofTrack: audioAssetTrack!, atTime: duration)
                            }
                }
                
            } catch {
                
            }
            
            
            let currentAssetLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)
            var currentOrientation = UIImageOrientation.Up
            var isCurrentAssetPortrait = false
            let currentTransform = assetTrack.preferredTransform
            let size = assetTrack.naturalSize ?? .zero

            if currentTransform.a == 0 && currentTransform.b == 1.0 && currentTransform.c == -1.0 && currentTransform.d == 0 {
                currentOrientation = UIImageOrientation.Right
                isCurrentAssetPortrait = true
            }
            if currentTransform.a == 0 && currentTransform.b == -1.0 && currentTransform.c == 1.0 && currentTransform.d == 0 {
                currentOrientation = UIImageOrientation.Left
                isCurrentAssetPortrait = true
            }
            if currentTransform.a == 1.0 && currentTransform.b == 0 && currentTransform.c == 0 && currentTransform.d == -1.0 {
                currentOrientation = UIImageOrientation.Up
            }
            if currentTransform.a == -1.0 && currentTransform.b == 0 && currentTransform.c == 0 && currentTransform.d == 1.0 {
                currentOrientation = UIImageOrientation.Down
            }
            
            var forstAssetScaleToFitRatio = self.view.frame.size.width / assetTrack.naturalSize.width
            if isCurrentAssetPortrait {
                forstAssetScaleToFitRatio = assetTrack.naturalSize.width / assetTrack.naturalSize.height
                
                let firstAssetScaleFactor = CGAffineTransformMakeScale(CGFloat(forstAssetScaleToFitRatio), CGFloat(forstAssetScaleToFitRatio))

                currentAssetLayerInstruction.setTransform(CGAffineTransformConcat(assetTrack.preferredTransform,firstAssetScaleFactor), atTime: duration)
            } else {//Land scape state
                
                let firstAssetScaleToYRatio = assetTrack.naturalSize.height * forstAssetScaleToFitRatio / self.view.frame.size.height
                let delta = (1 - firstAssetScaleToYRatio) * self.view.frame.height / 2.0

                let firstAssetScaleFactor = CGAffineTransformMakeScale(CGFloat(forstAssetScaleToFitRatio), CGFloat(forstAssetScaleToFitRatio))

                let concat = CGAffineTransformConcat(CGAffineTransformConcat(assetTrack.preferredTransform, firstAssetScaleFactor), CGAffineTransformMakeTranslation(0, delta))
                    currentAssetLayerInstruction.setTransform(concat, atTime: duration)
                
            }
            
            
            duration = CMTimeAdd(duration, timeDurations[i].CMTimeRangeValue.duration)
            currentAssetLayerInstruction .setOpacity(0.0, atTime: duration)
            arrayInstructions.append(currentAssetLayerInstruction)
            }
        
        print(composition)
        
        var totalTimeRange: CMTimeRange = kCMTimeRangeZero
        for timeRange in timeDurations {
            totalTimeRange = creatTimeRangeFromTwo(totalTimeRange, secondTimeRange: timeRange.CMTimeRangeValue)
        }
        
        print(totalTimeRange)
        
        if let audioAsset = audioAsset {
            //haveManualAudio = true
            let aAudioAssetTrack : AVAssetTrack = audioAsset.tracksWithMediaType(AVMediaTypeAudio)[0]
            let audioTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do{
                try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, duration), ofTrack: aAudioAssetTrack, atTime: kCMTimeZero)
            }catch _{
                print("add audio fail")
            }
            
        }
        
        
        var realTimeRange : CMTimeRange = kCMTimeRangeZero
        realTimeRange = CMTimeRange(start: kCMTimeZero, duration: duration.convertScale(30, method:.RoundAwayFromZero))
        
        mainInstruction.timeRange = totalTimeRange
        mainInstruction.layerInstructions = arrayInstructions

        let mainCompositionInst = AVMutableVideoComposition()
        mainCompositionInst.instructions = [mainInstruction]
        mainCompositionInst.frameDuration = CMTimeMake(1, 30)
        mainCompositionInst.renderSize = self.view.frame.size
        
        
        let videoFileUrl = NSURL(fileURLWithPath: resultFilePath)
        print("video file url", resultFilePath)
        if NSFileManager.defaultManager().fileExistsAtPath(resultFilePath) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(resultFilePath)
            } catch {
                
            }
        }
        
        let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        assetExport?.outputFileType = AVFileTypeQuickTimeMovie
        assetExport?.videoComposition = mainCompositionInst
        assetExport?.outputURL = videoFileUrl
        assetExport?.exportAsynchronouslyWithCompletionHandler({
             if let assetExport = assetExport {
                switch assetExport.status {
                    
                case .Failed:
                    dispatch_async(dispatch_get_main_queue(), {
                        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                        self.showAlertWith("Cannot merge videod!", title: "Error")
                    })
                    print("------------ Error --------- : merge 5 files",assetExport.error)
                    
                    break
                case .Cancelled:
                    dispatch_async(dispatch_get_main_queue(), {
                        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                        self.showAlertWith("Cannot merge videod!", title: "Error")
                    })
                    print("------------ Error --------- : merge 5 files")
                    break
                case .Completed:
                    dispatch_async(dispatch_get_main_queue(), {
                        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                        self.showAlertWith("Successfully Merged!", title: "Success")
                    })
                    break
                default:
                    
                    break
                }
            }
        })
    }
    private func timeDurationMake() {
        
        timeDurations.removeAll()
        
        for asset in assets! {
            if asset.isVideo {
                let time = Int(asset.duration!) * TIMESCALE
                let timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(Int64(Int(time)), Int32(TIMESCALE)))
                self.timeDurations.append(NSValue.init(CMTimeRange: timeRange))
            } else {
                let index = assets?.indexOf(asset)
                let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index!, inSection: 0)) as! AssetTableViewCell
                let strDuration = cell.txtDurationOfPhoto.text
                var time = 0
                if let strDuration = strDuration {
                    time = Int(strDuration)! * TIMESCALE
                }
                let timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(Int64(Int(time)), Int32(TIMESCALE)))
                self.timeDurations.append(NSValue.init(CMTimeRange: timeRange))
            }
        }
    }
    
    private func makeAVAssetList() {
        assetTrackList = [AVAssetTrack]()
        assetTrackAudioList = [AVAssetTrack]()
        
        if let assets = assets {
            var avIndex = 0
            
            for i in 0 ... assets.count - 1 {
                
                if assets[i].isVideo {
                    let assetTrack = av_AssetList[avIndex].tracksWithMediaType(AVMediaTypeVideo)[0]
                     let assetAudioTrack: AVAssetTrack?
                    if av_AssetList[avIndex].tracksWithMediaType(AVMediaTypeAudio).count != 0 {
                        assetAudioTrack = av_AssetList[avIndex].tracksWithMediaType(AVMediaTypeAudio)[0]
                    } else {
                        assetAudioTrack = nil
                    }
                    assetTrackList.append(assetTrack)
                    assetTrackAudioList.append(assetAudioTrack)
                    avIndex = avIndex + 1
                } else {
                    let assetTrack = imageAsset.tracksWithMediaType(AVMediaTypeVideo)[0]
                    assetTrackList.append(assetTrack)
                    assetTrackAudioList.append(nil)
                    
                }
            }
        }
        if let asset = audioAsset{
            let assetTrack = asset.tracksWithMediaType(AVMediaTypeAudio)[0]
            assetTrackAudioList.removeAll()
            assetTrackAudioList.append(assetTrack)
        }
    }
    private func creatTimeRangeFromTwo(firstTimeRange: CMTimeRange, secondTimeRange: CMTimeRange) -> CMTimeRange {
        let firstDuration = firstTimeRange.duration.value
        let secondDuration = secondTimeRange.duration.value
        let totalDuration = firstDuration + secondDuration
        
        return CMTimeRangeMake(kCMTimeZero, CMTimeMake(totalDuration, firstTimeRange.duration.timescale))
    }
    
    private func showAlertWith(message: String?, title: String?) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        alertVC.addAction(okAction)
        self.presentViewController(alertVC, animated: true, completion: nil)
    }
    // Mark: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (assets?.count)!
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AssetTableViewCell") as! AssetTableViewCell
        cell.lblOrderNumber.text = "Clip \(indexPath.row + 1)"
        let asset = (assets?[indexPath.row])! as DKAsset
        if asset.isVideo {
            cell.txtDurationOfPhoto.hidden = true
            cell.lblDurationSecond.hidden = true
            cell.lblMediaType.text = "Video"
        } else {
            cell.txtDurationOfPhoto.hidden = false
            cell.lblDurationSecond.hidden = false
            cell.lblMediaType.text = "Photo"
        }
        return cell
    }
    
    // Mark: UITableViewDelegate
    func tableView(tableView: UITableView, canMoveRowAt indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, moveRowAt sourceIndexPath: NSIndexPath
        , to destinationIndexPath: NSIndexPath) {
        let preAsset = assets?[sourceIndexPath.row]
        assets?.removeAtIndex(sourceIndexPath.row)
        assets?.insert(preAsset!, atIndex: destinationIndexPath.row)
        tableView.reloadData()
        getAVAssets()
    }
    
    func tableView(tableView: UITableView, canEditRowAt indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAt indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.None
    }
    
    
    func didSelectedMusicFile(item:MPMediaItem){
        print("selected : \(item.title)")
        if let assetURL = item.assetURL{
            audioAsset = AVAsset(URL: assetURL)
        }
        
    }
}
