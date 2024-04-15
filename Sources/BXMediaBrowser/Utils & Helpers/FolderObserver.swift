//----------------------------------------------------------------------------------------------------------------------
//
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//----------------------------------------------------------------------------------------------------------------------


import Foundation
import BXSwiftUtils


//----------------------------------------------------------------------------------------------------------------------


public class FolderObserver : NSObject
{
	/// The URL of the directory to be observed
	
    private let url:URL
    
    /// An externally supplied closure that will be called when the directory (or its contents) is modififed
	
	public var folderDidChange:(()->Void)? = nil
	
	/// A file descriptor for the monitored directory
	
    private var fileDescriptor:CInt = -1
    
    /// A dispatch source to monitor a file descriptor created from the directory
	
    private var monitorSource:DispatchSourceFileSystemObject? = nil
   
    /// The last known snapshot of folder contents. This is used to determine if any relevant changes have actually occured, or if a change event should be discarded.
	
	private var lastSnapshot:[String:(Int,Date)] = [:]
   
  
//----------------------------------------------------------------------------------------------------------------------


    public init(url:URL)
    {
		self.url = url
		super.init()
		self.lastSnapshot = self.createSnapshot()
    }
    
    
    deinit
    {
		self.cancel()
		self.cancelAllDelayedPerforms()
    }
    

//----------------------------------------------------------------------------------------------------------------------


    public func resume()
    {
		guard monitorSource == nil && fileDescriptor == -1 else { return }
		
		// Open the folder referenced by URL for monitoring only
		
		self.fileDescriptor = open(url.path, O_EVTONLY)
 		guard fileDescriptor != -1 else { return }
		
		// Define a dispatch source monitoring the folder for additions, deletions, and renamings
		
		let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor:fileDescriptor, eventMask:[.write,.delete], queue:DispatchQueue.main)
		self.monitorSource = source
    
		// Define the block to call when a file change is detected
		
		self.monitorSource?.setEventHandler
		{
			[weak self] in
			guard let self = self else { return }
			print("\(Self.self).\(#function) monitorSource.data = \(source.data)")
			self._folderDidChange()
		}
    
		// Define a cancel handler to ensure the directory is closed when the source is cancelled
		
		monitorSource?.setCancelHandler
		{
			[weak self] in
			guard let self = self else { return }
			close(self.fileDescriptor)
			self.fileDescriptor = -1
			self.monitorSource = nil
		}
    
		// Start monitoring the directory via the source
		
		monitorSource?.resume()
	}
    
    
    public func suspend()
    {
		monitorSource?.suspend()
    }
    
    
    public func cancel()
    {
		monitorSource?.cancel()
    }


//----------------------------------------------------------------------------------------------------------------------


	/// This function is called when a file system event for our folder has been detected. This can fire multiple times.
	
	func _folderDidChange()
	{
		self.performCoalesced(#selector(__folderDidChange), delay:1.0)
	}
	
	
	/// This function is called only once, after a specified delay.
	
	@objc func __folderDidChange()
	{
		// Create a folder contents snapshot and compare it with the last one
		
		let currentSnapshot = self.createSnapshot()
		defer { self.lastSnapshot = currentSnapshot }
		
		// If the contents have really changed, then call the external handler
		
		if !isEqual(lastSnapshot,currentSnapshot)
		{
			DispatchQueue.main.async
			{
				BXMediaBrowser.log.debug {"\(Self.self).\(#function) Folder contents have changed -> CALL HANDLER"}
				self.folderDidChange?()
			}
		}
		
		// If not, then simply ignore this event
		
		else
		{
			BXMediaBrowser.log.debug {"\(Self.self).\(#function) No relevant changes detected -> DISCARDING EVENT"}
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	/// This helper function creates a snapshots of important info of the folder contents.
	///
	/// For each file the size and modification date are stored. These can be used to compare user relevant changes later.
	
	internal func createSnapshot() -> [String:(Int,Date)]
	{
		// Gather folder contents, and filter out files that are invisible or not readable
		
		let filenames = (try? FileManager.default.contentsOfDirectory(atPath:url.path)) ?? []

		let urls = filenames.compactMap
		{
			(filename:String) -> URL? in
			let url = url.appendingPathComponent(filename)
			guard url.isFileURL else { return nil }
			guard url.isReadable else { return nil }
			guard !url.isHidden else { return nil }
			return url
		}

		// Build the snapshot dictionary. The filename is the key. File size and modification date are the value.
		
		var snapshot:[String:(Int,Date)] = [:]
		
		for url in urls
		{
			let filename = url.lastPathComponent
			let fileSize = url.fileSize ?? 0
			let modificationDate = url.modificationDate ?? Date()
			snapshot[filename] = (fileSize,modificationDate)
		}
		
		return snapshot
	}


	/// Returns true if two snapshots are equal
	
	internal func isEqual(_ snapshot1:[String:(Int,Date)],_ snapshot2:[String:(Int,Date)]) -> Bool
	{
		// Both folders need to contain equal number of files
		
		guard snapshot1.count == snapshot2.count else { return false }
		
		// For each file compare file size and modification date. The key in the snapshot dictionary is the filename
		
		for key in snapshot1.keys
		{
			guard let (size1,date1) = snapshot1[key] else { return false }
			guard let (size2,date2) = snapshot2[key] else { return false }
			guard size1 == size2 else { return false }
			guard date1 == date2 else { return false }
		}
		
		return true
	}
}


//----------------------------------------------------------------------------------------------------------------------
 
 
