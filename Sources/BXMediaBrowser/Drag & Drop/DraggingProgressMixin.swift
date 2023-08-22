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


#if os(macOS)

import BXSwiftUtils
import BXSwiftUI
import AppKit


//----------------------------------------------------------------------------------------------------------------------


// MARK: -
	
public protocol DraggingProgressMixin : AnyObject
{
	/// The (optional) title for the download progress window
	
	var progressTitle:String? { get }
	
 	/// The (optional) message for the download progress window
	
	var progressMessage:String? { get }
	
   /// The Progress object for the current download/copy operation
	
    var progress:Progress? { set get }
    
    /// The start time of a download/copy operation
	
    var progressStartTime:CFAbsoluteTime { set get }
    
    /// KVO observers
	
	var progressObserver:Any? { set get }
    
    /// How often has progress been started
	
	var progressRetainCount:Int { set get }
}

	
//----------------------------------------------------------------------------------------------------------------------

 
// MARK: -
	
extension DraggingProgressMixin
{
	/// Creates a root Progress object with the specified totalUnitCount
	
	@discardableResult public func prepareProgress(with count:Int, showImmediately:Bool = false) -> Progress
	{
		var progress:Progress
		
		// Check if there is still a previous async operation in progress - in this case we can
		// reuse the Progress instance and just update the totalUnitCount. The window of the
		// BXProgressWindowController is already open.
		
		if let existing = Progress.current() ?? Progress.globalParent
		{
			progress = existing
			progress.totalUnitCount += Int64(clamping:count)
		}
		else
		{
			// Nope, so create a new root Progress
		
			Progress.globalParent = nil
			
			progress = Progress(parent:nil, userInfo:nil)		// Using this init doesn't link parent to possibly still existing Progress.current()
			progress.totalUnitCount = Int64(clamping:count)
			self.progress = progress
			
			Progress.globalParent = progress

			// Register KVO observers
			
			self.progressObserver = progress.publisher(for:\.fractionCompleted, options:.new).sink
			{
				[weak self] in self?.updateProgress($0)
			}
			
			BXProgressWindowController.shared.cancelHandler =
			{
				[weak self] in self?.cancelProgress()
			}

			// Initial values
			
			self.progressStartTime = CFAbsoluteTimeGetCurrent()

			self.setProgress(0.0)
		}

		// Increment useCount of the singleton
		
		self.progressRetainCount += 1

		// If requested, show the progress bar immediately
		
		if showImmediately && !BXProgressWindowController.shared.isVisible
		{
			BXProgressWindowController.shared.show()
		}
		
		// Make progress key (just it case it wasn't before), so that progress bar is blue
		
		BXProgressWindowController.shared.window?.makeKey() //AndOrderFront(nil)
		
		return progress
	}
	
	
	/// Updates the progress UI with the specified fraction
	
	private func updateProgress(_ fraction:Double)
	{
		DispatchQueue.main.asyncIfNeeded
		{
			let now = CFAbsoluteTimeGetCurrent()
			let dt = now - self.progressStartTime
			let percent = Int(fraction*100)
			
			self.setProgress(fraction)
			
			if !BXProgressWindowController.shared.isVisible && dt>0.5 //&& fraction<0.6
			{
				logDragAndDrop.debug {"\(Self.self).\(#function)  show progress window"}
				BXProgressWindowController.shared.show()
			}

			logDragAndDrop.verbose {"\(Self.self).\(#function)  progress=\(percent)%%  duration=\(dt)s"}
		}
	}
	
	
	/// Update the progress UI with the specified fraction
	
	private func setProgress(_ fraction:Double)
	{
		BXProgressWindowController.shared.title = self.progressTitle ?? NSLocalizedString("Importing Media Files", bundle:.BXMediaBrowser, comment:"Progress Title")
		BXProgressWindowController.shared.message = self.progressMessage ?? NSLocalizedString("Downloading", bundle:.BXMediaBrowser, comment:"Progress Message")
		BXProgressWindowController.shared.value = fraction
		BXProgressWindowController.shared.isIndeterminate = false
	}
	
	
	/// Hides the progress UI
	
	public func hideProgress()
	{
		logDragAndDrop.debug {"\(Self.self).\(#function)"}
		
		self.progressRetainCount -= 1
		
		if progressRetainCount <= 0
		{
			BXProgressWindowController.shared.hide()
			self.cleanupProgress()
		}
	}


	/// Cancels the currently running download/copy operation
	
	public func cancelProgress()
	{
		logDragAndDrop.debug {"\(Self.self).\(#function)"}
		
		BXProgressWindowController.shared.hide()
		self.cleanupProgress()
	}
	

	/// Cleanup after using progress
	
	public func cleanupProgress()
	{
		logDragAndDrop.debug {"\(Self.self).\(#function)"}
		
		BXProgressWindowController.shared.cancelHandler = nil

		Progress.globalParent = nil

		self.progress = nil
		self.progressObserver = nil
		self.progressRetainCount = 0
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
