//
//  SearchViewController.swift
//  HalfTunes
//
//  Created by Ken Toh on 13/7/15.
//  Copyright (c) 2015 Ken Toh. All rights reserved.
//

import UIKit
import MediaPlayer

class SearchViewController: UIViewController {

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var searchBar: UISearchBar!
    
  let defaultSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())

  var dataTask: NSURLSessionDataTask?
  var searchResults = [Track]()
  var activeDownloads = [String: Download]()
    
    
  
  lazy var tapRecognizer: UITapGestureRecognizer = {
    var recognizer = UITapGestureRecognizer(target:self, action: "dismissKeyboard")
    return recognizer
  }()
    
  
  // MARK: View controller methods
    lazy var downloadsSession: NSURLSession = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.tableFooterView = UIView()
    
  
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: Handling Search Results
  
  // This helper method helps parse response JSON NSData into an array of Track objects.
  func updateSearchResults(data: NSData?) {
    searchResults.removeAll()
    do {
      if let data = data, response = try NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions(rawValue:0)) as? [String: AnyObject] {
        
        // Get the results array
        if let array: AnyObject = response["results"] {
          for trackDictonary in array as! [AnyObject] {
            if let trackDictonary = trackDictonary as? [String: AnyObject], previewUrl = trackDictonary["previewUrl"] as? String {
              // Parse the search result
              let name = trackDictonary["trackName"] as? String
              let artist = trackDictonary["artistName"] as? String
              searchResults.append(Track(name: name, artist: artist, previewUrl: previewUrl))
            } else {
              print("Not a dictionary")
            }
          }
        } else {
          print("Results key not found in dictionary")
        }
      } else {
        print("JSON Error")
      }
    } catch let error as NSError {
      print("Error parsing results: \(error.localizedDescription)")
    }
    
    dispatch_async(dispatch_get_main_queue()) {
      self.tableView.reloadData()
      self.tableView.setContentOffset(CGPointZero, animated: false)
    }
  }
  
  // MARK: Keyboard dismissal
  
  func dismissKeyboard() {
    searchBar.resignFirstResponder()
  }
  
  // MARK: Download methods
    
    func trackIndexForDownloadTask(downloadTask: NSURLSessionDownloadTask) -> Int? {
        if let url = downloadTask.originalRequest?.URL?.absoluteString {
            for(index, track) in searchResults.enumerate() {
                if url == track.previewUrl! {
                    return index
                }
            }
        }
        return nil
    }
  
  // Called when the Download button for a track is tapped
  func startDownload(track: Track) {
    // TODO
    if let urlString = track.previewUrl, url = NSURL(string: urlString) {
        let download = Download(url: urlString)
        download.downloadTask = downloadsSession.downloadTaskWithURL(url)
        download.downloadTask!.resume()
        download.isDownloading = true
        activeDownloads[download.url] = download
    }
  }
  
  // Called when the Pause button for a track is tapped
  func pauseDownload(track: Track) {
    // TODO
  }
  
  // Called when the Cancel button for a track is tapped
  func cancelDownload(track: Track) {
    // TODO
  }
  
  // Called when the Resume button for a track is tapped
  func resumeDownload(track: Track) {
    // TODO
  }
  
   // This method attempts to play the local file (if it exists) when the cell is tapped
  func playDownload(track: Track) {
    if let urlString = track.previewUrl, url = localFilePathForUrl(urlString) {
      let moviePlayer:MPMoviePlayerViewController! = MPMoviePlayerViewController(contentURL: url)
      presentMoviePlayerViewControllerAnimated(moviePlayer)
    }
  }
  
  // MARK: Download helper methods
  
  // This method generates a permanent local file path to save a track to by appending
  // the lastPathComponent of the URL (i.e. the file name and extension of the file)
  // to the path of the app’s Documents directory.
  func localFilePathForUrl(previewUrl: String) -> NSURL? {
    let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
    if let url = NSURL(string: previewUrl), lastPathComponent = url.lastPathComponent {
        let fullPath = documentsPath.stringByAppendingPathComponent(lastPathComponent)
        return NSURL(fileURLWithPath:fullPath)
    }
    return nil
  }
  
  // This method checks if the local file exists at the path generated by localFilePathForUrl(_:)
  func localFileExistsForTrack(track: Track) -> Bool {
    if let urlString = track.previewUrl, localUrl = localFilePathForUrl(urlString) {
      var isDir : ObjCBool = false
      if let path = localUrl.path {
        return NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir)
      }
    }
    return false
  }
}

// MARK: - UISearchBarDelegate

extension SearchViewController: UISearchBarDelegate {
  func searchBarSearchButtonClicked(searchBar: UISearchBar) {
    // Dimiss the keyboard
    dismissKeyboard()
    
    if !searchBar.text!.isEmpty {
        if dataTask != nil {
            dataTask?.cancel()
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let expectedCharSet = NSCharacterSet.URLQueryAllowedCharacterSet()
        let searchTerm = searchBar.text!.stringByAddingPercentEncodingWithAllowedCharacters(expectedCharSet)!
        let url = NSURL(string: "https://itunes.apple.com/search?media=music&entity=song&term=\(searchTerm)")
        
        //
        dataTask = defaultSession.dataTaskWithURL(url!) { data, response, error in
        dispatch_async(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        if let error = error {
            print(error.localizedDescription)
        } else if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                print(String(data))
                self.updateSearchResults(data)
            }
        }
    }
    
        dataTask?.resume()
    
    }
  }
    
  func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
    return .TopAttached
  }
    
  func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
    view.addGestureRecognizer(tapRecognizer)
  }
    
  func searchBarTextDidEndEditing(searchBar: UISearchBar) {
    view.removeGestureRecognizer(tapRecognizer)
  }
}

// MARK: TrackCellDelegate

extension SearchViewController: TrackCellDelegate {
  func pauseTapped(cell: TrackCell) {
    if let indexPath = tableView.indexPathForCell(cell) {
      let track = searchResults[indexPath.row]
      pauseDownload(track)
      tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
    }
  }
  
  func resumeTapped(cell: TrackCell) {
    if let indexPath = tableView.indexPathForCell(cell) {
      let track = searchResults[indexPath.row]
      resumeDownload(track)
      tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
    }
  }
  
  func cancelTapped(cell: TrackCell) {
    if let indexPath = tableView.indexPathForCell(cell) {
      let track = searchResults[indexPath.row]
      cancelDownload(track)
      tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
    }
  }
  
  func downloadTapped(cell: TrackCell) {
    if let indexPath = tableView.indexPathForCell(cell) {
      let track = searchResults[indexPath.row]
      startDownload(track)
      tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: indexPath.row, inSection: 0)], withRowAnimation: .None)
    }
  }
}

// MARK: UITableViewDataSource

extension SearchViewController: UITableViewDataSource {
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return searchResults.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("TrackCell", forIndexPath: indexPath) as!TrackCell
    
    // Delegate cell button tap events to this view controller
    cell.delegate = self
    
    let track = searchResults[indexPath.row]
    
    // Configure title and artist labels
    cell.titleLabel.text = track.name
    cell.artistLabel.text = track.artist

    // If the track is already downloaded, enable cell selection and hide the Download button
    let downloaded = localFileExistsForTrack(track)
    cell.selectionStyle = downloaded ? UITableViewCellSelectionStyle.Gray : UITableViewCellSelectionStyle.None
    cell.downloadButton.hidden = downloaded
    
    return cell
  }
}

// MARK: UITableViewDelegate

extension SearchViewController: UITableViewDelegate {
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 62.0
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let track = searchResults[indexPath.row]
    if localFileExistsForTrack(track) {
      playDownload(track)
    }
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }
}

extension SearchViewController : NSURLSessionDelegate {
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        print("Finished Downloading")
        if let originalURL = downloadTask.originalRequest?.URL?.absoluteString, destinationURL = localFilePathForUrl(originalURL) {
            print(destinationURL)
            
            let fileManager = NSFileManager.defaultManager()
            
            do {
                try fileManager.removeItemAtURL(destinationURL)
            } catch let error as NSError {
                print("Could not copy file to disk: \(error.localizedDescription)")
            }
        }
        
        if let url = downloadTask.originalRequest?.URL?.absoluteString {
            activeDownloads[url] = nil
            if let trackIndex = trackIndexForDownloadTask(downloadTask) {
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: trackIndex, inSection: 0)], withRowAnimation: .None)
                })
            }
        }
    }
}

