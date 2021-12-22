//
//  FolderObserver.swift
//  MediaBrowserTest
//
//  Created by Peter Baumgartner on 04.12.21.
//

import Foundation


//----------------------------------------------------------------------------------------------------------------------


public class FolderObserver : NSObject
{
    private let url: URL
    
	public var folderDidChange:(() -> Void)? = nil
	
	/// A file descriptor for the monitored directory
	
    private var fileDescriptor: CInt = -1
    
    /// A dispatch source to monitor a file descriptor created from the directory
	
    private var monitorSource:DispatchSourceFileSystemObject? = nil
   
  
//----------------------------------------------------------------------------------------------------------------------


    public init(url:URL)
    {
		self.url = url
    }
    
    
    deinit
    {
		self.cancel()
		self.cancelAllDelayedPerforms()
    }
    

//----------------------------------------------------------------------------------------------------------------------


    func resume()
    {
		guard monitorSource == nil && fileDescriptor == -1 else
		{
			return
		}
		
		// Open the folder referenced by URL for monitoring only
		
		fileDescriptor = open(url.path, O_EVTONLY)
    
		// Define a dispatch source monitoring the folder for additions, deletions, and renamings
		
		monitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor:fileDescriptor, eventMask:.write, queue:DispatchQueue.main)
    
		// Define the block to call when a file change is detected
		
		monitorSource?.setEventHandler
		{
			[weak self] in self?._folderDidChange()
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
    
    
    func suspend()
    {
		monitorSource?.suspend()
    }
    
    
    func cancel()
    {
		monitorSource?.cancel()
    }


//----------------------------------------------------------------------------------------------------------------------


	func _folderDidChange()
	{
		self.performCoalesced(#selector(__folderDidChange), delay:1.0)
	}
	
	
	@objc func __folderDidChange()
	{
		DispatchQueue.main.async
		{
			self.folderDidChange?()
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------
 
