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


//----------------------------------------------------------------------------------------------------------------------


public class FolderObserver : NSObject
{
	/// The URL of the directory to be observed
	
    private let url: URL
    
    /// An externally supplied closure that will be called when the directory (or its contents) is modififed
	
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
 
