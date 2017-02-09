//
////  ViewController.swift
//  TrimViewController
//
//  Created by Akira on 11/20/16.
//  Copyright © 2016 Akira. All rights reserved.

import UIKit
import MediaPlayer
import AVFoundation
import AVKit
import Photos
import AssetsLibrary
import DKImagePickerController
import MobileCoreServices
import OKAlertController
import MBProgressHUD

/* c function for cretaing url from name */
func dataFilePath(path: String) -> NSURL {
    //creating a path for file and checking if it already exist if exist then delete it
    let outputPath = "\(NSTemporaryDirectory())\(path)"
    var success: Bool
    let fileManager = NSFileManager.defaultManager()
    //check if file exist at outputPath
    success = fileManager.fileExistsAtPath(outputPath)
    if success {
        //delete if file exist at outputPath
        do {
            try fileManager.removeItemAtPath(outputPath)
        }
        catch {
        }
    }
    return NSURL(fileURLWithPath: outputPath)
}

class TrimViewController: UIViewController,UITableViewDelegate,MPMediaPickerControllerDelegate, UIImagePickerControllerDelegate, ICGVideoTrimmerDelegate,UINavigationControllerDelegate {
    var get_video: [DKAsset]?
    
    var isPlaying = false
    var isFirstInitialzed = false
    var player: AVQueuePlayer!
    var playerItem: AVPlayerItem!
    var playerLayer: AVPlayerLayer?
    var exportSession: AVAssetExportSession!
    var playbackTimeCheckerTimer: NSTimer!
    var videoPlaybackPosition: CGFloat = 0.0
    
    @IBOutlet weak var trimmerView: ICGVideoTrimmerView?
    @IBOutlet weak var trimButton: UIButton?
    @IBOutlet weak var pasteButton: UIButton?
    @IBOutlet weak var MusicaddButton: UIButton?
    @IBOutlet weak var SoundonButton: UIButton?
    @IBOutlet weak var DraftButton: UIButton?
    @IBOutlet weak var muteUnmuteButton: UIButton!
    @IBOutlet weak var videoPlayer: UIView?
    @IBOutlet weak var videoLayer: UIView?
    var tempVideoPath = ""
    var originalURL: NSURL!
    var get_VideoUrl:NSURL!
    var finalvideo_url:NSURL!
    var trimUrl: NSURL!
    var tempUrl: NSURL!
    var asset: AVAsset!
    var test_AssetList: [AVAsset]!
    var startTime: CGFloat = 0.0
    var stopTime: CGFloat = 0.0
    var index: Int = 0
    var trimedVideoIndex = 0
    var trim_flag = false
    
    var AudioAsset: AVAsset?
    var Audio_flag = false
    
  
    let sound_offbutton_img = UIImage(named: "sound_off2.png")
    let sound_onbutton_img = UIImage(named: "sound_on2.png")

    var VideoUrl1: NSURL?
    var VideoUrl2: NSURL?
    var test_urlarray : [NSURL]!
    var result_videourl : NSMutableArray = []
    var getvideourlarray : [NSURL]!

    let finalvideo_path = NSBundle.mainBundle().pathForResource("video04", ofType: "mp4")
    
    var video_num:NSInteger = 0
    var test_Dic = [String : String]()
    var total_dic : [NSDictionary] = [NSDictionary]()
    var play_item :[AVPlayerItem] = [AVPlayerItem]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //********** button set part *********
        
        
        self.pasteButton!.hidden = true
        self.tempUrl = dataFilePath("tmpLibraryVideo.mp4")

        self.trimmerView?.maxLength = 20
        self.trimmerView?.thumbWidth = 10.5
        self.trimmerView?.showsRulerView = false
        navigationController?.interactivePopGestureRecognizer?.enabled = false
        
        
        self.muteUnmuteButton.setImage(sound_offbutton_img, forState: .Normal)
        let backButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: #selector(self.goBack))
        self.navigationItem.leftBarButtonItem = backButtonItem
        
        self.originalURL = get_VideoUrl
        finalvideo_url = NSURL(fileURLWithPath: finalvideo_path!)

        self.updateParameters(originalURL! as NSURL)

    }
    
    func goBack() {
        self.player.pause()
        self.navigationController?.popViewControllerAnimated(true)
    }

    // MARK:- videoTrim
    @IBAction func trimVideo(sender: UIButton) {
        let compatiblePresets = AVAssetExportSession.exportPresetsCompatibleWithAsset(self.asset)
        if compatiblePresets.contains(AVAssetExportPresetMediumQuality) {
            self.exportSession = AVAssetExportSession(asset: self.asset, presetName: AVAssetExportPresetPassthrough)
            // Implementation continues.
            let furl = dataFilePath("tmpMov\(trimedVideoIndex).mp4")
            //url of exportedVideo
            self.exportSession.outputURL = furl
            self.exportSession.outputFileType = AVFileTypeQuickTimeMovie
            let start = CMTimeMakeWithSeconds(Float64(self.startTime), self.asset.duration.timescale)
            let duration = CMTimeMakeWithSeconds(Float64(self.stopTime) - Float64(self.startTime), self.asset.duration.timescale)
            let range = CMTimeRangeMake(start, duration)
            self.exportSession.timeRange = range
            self.exportSession.exportAsynchronouslyWithCompletionHandler({() -> Void in
                switch self.exportSession.status {
                case .Failed:
                    print("Export failed: (self.exportSession.error?.localizedDescription)")
                case .Cancelled:
                    print("Export canceled")
                default:
                    print("NONE")
                    self.trim_flag = true
                    self.trimedVideoIndex += 1
                    self.trimUrl = self.exportSession.outputURL!
                    dispatch_async(dispatch_get_main_queue(), {
                        self.pasteButton?.enabled = true
                        self.pasteButton?.hidden = false
                    })
                    self.resetPlayerToNewUrl(self.trimUrl)
                    print("trimurl",self.trimUrl)
                }
            })
        }
    }
    //**********************************************************
    func resetPlayerToNewUrl(videoUrl: NSURL) {
        dispatch_async(dispatch_get_main_queue(), {
            self.asset = AVAsset(URL: videoUrl)
            let playerItem = AVPlayerItem(asset: self.asset!)
            self.player.replaceCurrentItemWithPlayerItem(playerItem)
            self.trimmerView?.asset = self.asset
            self.trimmerView?.resetSubviews()
            self.startTime = 0
            self.seekAll()
        })
    }
    
    func appendVideo(videoUrl: NSURL, with finalVideoUrl: NSURL) {
        
//        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        let avAsset1 = AVURLAsset(URL: videoUrl, options: nil)
        let avAsset2 = AVURLAsset(URL: finalVideoUrl, options: nil)
        
        var duration1: CGFloat = 0.0
        var duration2: CGFloat = 0.0
        duration1 = CGFloat(CMTimeGetSeconds(avAsset1.duration))
        duration2 = CGFloat(CMTimeGetSeconds(avAsset2.duration))
       // self.trimmerView?.maxLength = (duration1 + duration2)*1.0

      //  s//elf.trimmerView?.thumbWidth = 14.6
        self.trimmerView?.showsRulerView = true

        
        let composition = AVMutableComposition()
        let compositionTrackVideo = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        let compositionTrackAudio = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        var assetVideoTracks1 = avAsset1.tracksWithMediaType(AVMediaTypeVideo)
        var assetVideoTracks2 = avAsset2.tracksWithMediaType(AVMediaTypeVideo)
        
        
        var assetAudioTracks1 = avAsset1.tracksWithMediaType(AVMediaTypeAudio)
        var assetAudioTracks2 = avAsset2.tracksWithMediaType(AVMediaTypeAudio)
        
        var insertionPoint = kCMTimeZero
        
        let videoTrack1:AVAssetTrack = assetVideoTracks1[0] as AVAssetTrack
        let videoTrack2:AVAssetTrack = assetVideoTracks2[0] as AVAssetTrack
        
        
        let audioTrack1:AVAssetTrack = assetAudioTracks1[0] as AVAssetTrack
        let audioTrack2:AVAssetTrack = assetAudioTracks2[0] as AVAssetTrack
        
        do {
            try compositionTrackVideo.insertTimeRange(CMTimeRangeMake(kCMTimeZero, avAsset1.duration), ofTrack: videoTrack1, atTime: insertionPoint)
            try compositionTrackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero, avAsset1.duration), ofTrack: audioTrack1, atTime: insertionPoint)
            insertionPoint = CMTimeAdd(insertionPoint, avAsset1.duration)
            do {
                try compositionTrackVideo.insertTimeRange(CMTimeRangeMake(kCMTimeZero, avAsset2.duration), ofTrack: videoTrack2, atTime: insertionPoint)
                try compositionTrackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero, avAsset2.duration), ofTrack: audioTrack2, atTime: insertionPoint)
            }
            catch {
            }
        }
        catch {
        }
        
        compositionTrackVideo.preferredTransform = videoTrack1.preferredTransform
//        compositionTrackVideo.preferredTransform = videoTrack2.preferredTransform
        
        let newVideoUrl = dataFilePath("tmpMov.mp4")
        //url of exportedVideo
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
        exportSession.outputURL = newVideoUrl
        finalvideo_url = newVideoUrl
        exportSession.outputFileType = AVFileTypeQuickTimeMovie
        
        exportSession.exportAsynchronouslyWithCompletionHandler({ () -> Void in
            // Upon completion of the export,
            if exportSession.status == .Completed {
                self.Audio_flag = false
                self.index += 1
                if self.index == self.result_videourl.count {
                    
                    self.resetPlayerToNewUrl(self.finalvideo_url)
                    dispatch_async(dispatch_get_main_queue(), {
                        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                    })
                    return
                } else {
                    self.appendVideo(self.finalvideo_url, with: self.result_videourl[self.index] as! NSURL)
                }
            }
        })
    }

    func seekAll() {
        self.seekVideo(toPos: self.startTime)
        self.trimmerView?.seekToTime(self.startTime)
    }
    
    
    func trimmerView(trimmerView: ICGVideoTrimmerView, didChangeLeftPosition startTime: CGFloat, rightPosition endTime: CGFloat) {
        if startTime != self.startTime {
            //then it moved the left position, we should rearrange the bar
            self.seekVideo(toPos: startTime)
        }
        self.startTime = startTime
        self.stopTime = endTime
    }
    
    func updateParameters(withUrl: NSURL) {
        self.asset = AVAsset(URL: originalURL as NSURL)
        let item = AVPlayerItem(asset: self.asset)
        self.player = AVQueuePlayer(playerItem: item)
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.playerLayer!.contentsGravity = "resizeAspect"
        self.player.actionAtItemEnd = .None
        if let videoLayers = self.videoLayer?.layer.sublayers {
            for layer in videoLayers {
                layer.removeFromSuperlayer()
            }
        }
        
        self.videoLayer?.layer.addSublayer(self.playerLayer!)
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapOnVideoLayer))
        self.videoLayer?.addGestureRecognizer(tap)
        self.videoPlaybackPosition = 0
        self.tapOnVideoLayer(tap)
        // set properties for trimmer view
        self.trimmerView?.themeColor = UIColor.lightGrayColor()
        self.trimmerView?.asset = self.asset
        self.trimmerView?.showsRulerView = true
        self.trimmerView?.trackerColor = UIColor.yellowColor()
        self.trimmerView?.delegate = self
        self.trimmerView?.minLength = 0.1
        // important: reset subviews
        self.trimmerView?.resetSubviews()
        self.trimButton?.hidden = false
        self.muteUnmuteButton.enabled = true
        self.muteUnmuteButton.hidden = false
        self.isFirstInitialzed = true
    }

    override func viewDidLayoutSubviews() {
        self.playerLayer!.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat((self.videoLayer?.frame.size.width)!), height: CGFloat((self.videoLayer?.frame.size.height)!))
    }
    
    func tapOnVideoLayer(tap: UITapGestureRecognizer) {
        if self.isPlaying {
            self.player.pause()
            self.stopPlaybackTimeChecker()
            self.muteUnmuteButton.enabled = false
        }
        else {
            self.player.play()
            self.startPlaybackTimeChecker()
            self.muteUnmuteButton.enabled = true
        }
        self.isPlaying = !self.isPlaying
        self.trimmerView?.hideTracker(!self.isPlaying)
    }
    
    func startPlaybackTimeChecker() {
        self.stopPlaybackTimeChecker()
        self.playbackTimeCheckerTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(self.onPlaybackTimeCheckerTimer), userInfo: nil, repeats: true)
    }
    
    func stopPlaybackTimeChecker() {
        if (self.playbackTimeCheckerTimer != nil) {
            self.playbackTimeCheckerTimer.invalidate()
            self.playbackTimeCheckerTimer = nil
        }
    }
    
    func onPlaybackTimeCheckerTimer() {
        self.videoPlaybackPosition = CGFloat(CMTimeGetSeconds(self.player.currentTime()))
        self.trimmerView?.seekToTime(CGFloat(CMTimeGetSeconds(self.player.currentTime())))
        if self.videoPlaybackPosition >= self.stopTime {
            self.videoPlaybackPosition = self.startTime
            self.seekVideo(toPos: self.startTime)
            self.trimmerView?.seekToTime(self.startTime)
        }
    }
    
    func seekVideo(toPos pos: CGFloat) {
        self.videoPlaybackPosition = pos
        let time = CMTimeMakeWithSeconds(Float64(self.videoPlaybackPosition), self.player.currentTime().timescale)
        self.player.seekToTime(time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }
    
    @IBAction func Past_save_button(sender: AnyObject) {
        
        self.trim_flag = false
        self.player.pause()
    
        self.Save_currentvideodata(self.trimUrl)
        self.Video_merge()
        self.pasteButton?.hidden = true
//        self.ResultVideo_Paly()
        
    }
    func Video_merge(){
        
        print("trimed video data",self.result_videourl)
        print("test",result_videourl[index])
        
        self.appendVideo(finalvideo_url, with: result_videourl[index] as! NSURL)

        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        self.player.play()
    }
    
    func ResultVideo_Paly(){
        let path1 = NSBundle.mainBundle().pathForResource("video01", ofType: "mp4")
        let path2 = NSBundle.mainBundle().pathForResource("video02", ofType: "mp4")
        let path3 = NSBundle.mainBundle().pathForResource("video03", ofType: "mp4")
        
        let url1 = NSURL(fileURLWithPath: path1!)
        let url2 = NSURL(fileURLWithPath: path2!)
        let url3 = NSURL(fileURLWithPath: path3!)
        
        test_urlarray = [NSURL(fileURLWithPath:path1!),
                         NSURL(fileURLWithPath:path2!),
                         NSURL(fileURLWithPath:path3!)]
        
        
        self.appendVideo(finalvideo_url, with: test_urlarray[index])
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        self.player.play()
    }

    func Current_videosave(Video_Url:NSURL){
        print(self.trimUrl)
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        dispatch_async(dispatch_get_main_queue(), {
            let library = ALAssetsLibrary()
            if library.videoAtPathIsCompatibleWithSavedPhotosAlbum(Video_Url) {
                library.writeVideoAtPathToSavedPhotosAlbum(Video_Url, completionBlock: { (assetUrl, error) in
                    if let error = error {
                        print("Error====", error)
                        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                    } else {
                        print("Video Saved")
                        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                        self.showAlertWith("Success!", title: "Video Save!")
                    }
                })
            }
        })
    }

    func Get_Videodata(){
        
        
    }
    
    @IBAction func mute_Unmute(sender: AnyObject) {
        self.player.muted = !self.player.muted
        if self.player.muted {
            self.muteUnmuteButton.setImage(sound_onbutton_img, forState: .Normal)
        }
            
        else {
            self.muteUnmuteButton.setImage(sound_offbutton_img, forState: .Normal)
        }
    }
    
    @IBAction func Draft_button(sender: AnyObject) {
    }
    @IBAction func Add_music(sender: AnyObject) {
        self.player.pause()
        print("Please add music!")
        
        let mediaPicker = MPMediaPickerController(mediaTypes: .Music)
        mediaPicker.delegate = self
        mediaPicker.prompt = "Select song (Icloud songs must be downloaded to use)"
        mediaPicker.allowsPickingMultipleItems = false
        mediaPicker.showsCloudItems = false
        presentViewController(mediaPicker, animated: true, completion: {})
        
    }
    
    func mediaPicker(mediaPicker: MPMediaPickerController!, didPickMediaItems mediaItemCollection: MPMediaItemCollection!) {
        let selectedSongs = mediaItemCollection.items
        if selectedSongs.count > 0 {
            Audio_flag = true
            let song = selectedSongs[0]
            if let url = song.valueForProperty(MPMediaItemPropertyAssetURL) as? NSURL {
//                audioAsset = (AVAsset(URL:url) )
            
                AudioAsset = (AVAsset(URL:url))
                
                dismissViewControllerAnimated(true, completion: nil)
                let alert = UIAlertController(title: "Asset Loaded", message: "Audio Loaded", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler:nil))
                presentViewController(alert, animated: true, completion: nil)
            } else {
                dismissViewControllerAnimated(true, completion: nil)
                let alert = UIAlertController(title: "Asset Not Available", message: "Audio Not Loaded", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler:nil))
                presentViewController(alert, animated: true, completion: nil)
            }
        } else {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController!) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func Select_videofiles(sender: AnyObject) {
        
        self.player.pause()
        
        let alert = OKAlertController(title: "Please add!", message: "")
        
        alert.shadowColor = UIColor(white: 1,alpha: 0.6)
        alert.borderWidth = 1
        
        alert.addAction("Current Video Save!", style: .Default){ _ in
            if self.trim_flag {
                self.Current_videosave(self.trimUrl)
            }
            else{
                self.Current_videosave(self.finalvideo_url)
            }
        }
        
        alert.addAction("Camera", style: .Default) { _ in
            print("Ut enim ad minim veniam")
        }

        alert.addAction("Video Link", style: .Default) { _ in
            self.navigationController?.popToRootViewControllerAnimated(true)
        }

        alert.addAction("Library", style: .Default) { _ in
            
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .SavedPhotosAlbum
            imagePickerController.mediaTypes = [(kUTTypeMovie as String), (kUTTypeAVIMovie as String), (kUTTypeVideo as String), (kUTTypeMPEG4 as String)]
            imagePickerController.delegate = self
            imagePickerController.allowsEditing = false
            self.presentViewController(imagePickerController, animated: true, completion: nil)
            if self.trim_flag {
                self.Save_currentvideodata(self.trimUrl)
            }
        }

        alert.addAction("Cancel", style: .Cancel) { _ in
            self.player.play()
        }
        alert.show(fromController: self, animated: true)
    }
    
    
    func Save_currentvideodata(TrimvideoUrl : NSURL)
    {
        result_videourl.addObject(TrimvideoUrl)
        print(TrimvideoUrl)
    }
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])   {
        print("test!!")
        picker.dismissViewControllerAnimated(true, completion: { _ in })
        
        let url = (info[UIImagePickerControllerMediaURL] as! NSURL)
        self.trim_flag = false
        self.originalURL = url as NSURL

        dispatch_async(dispatch_get_main_queue(),{
            if self.isFirstInitialzed {
                self.trimUrl = nil
                dispatch_async(dispatch_get_main_queue(), {
                    self.pasteButton?.hidden = true
                })
                self.resetPlayerToNewUrl(self.originalURL)
                self.player.play()
            }
            else
                {
                    self.asset = AVAsset(URL: url as NSURL)
                    let item = AVPlayerItem(asset: self.asset)
                    self.player = AVQueuePlayer(playerItem: item)
                }
            
        })
    }
    
    
    func test_videoplay() {
        dispatch_async(dispatch_get_main_queue(), {
            let video_num = self.total_dic.count
            
            for dictionary in self.total_dic {
                let url = NSURL(string: dictionary.objectForKey("urlkey") as! String)
//                print(url)
                let items = AVPlayerItem(URL: url!)
                self.play_item.append(items)
                print(self.play_item)
            }
            
            self.player = AVQueuePlayer(items: self.play_item)
            self.trimmerView?.maxLength = 40.6
            self.trimmerView?.resetSubviews()
            self.startTime = 0
            self.seekAll()
            self.player.play()
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func showAlertWith(message: String?, title: String?) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        alertVC.addAction(okAction)
        self.presentViewController(alertVC, animated: true, completion: nil)
    }
}

