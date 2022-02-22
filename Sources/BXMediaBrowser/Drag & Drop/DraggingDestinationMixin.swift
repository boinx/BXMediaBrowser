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


public protocol DraggingDestinationMixin : AnyObject
{
	/// This handler is called for each received media file. In case of in-app drags,
	/// the optional Object instance may also be supplied to the handler.
	
	var receiveFileHandler:((URL?,Object?,Error?)->Void)? { set get }
	
	/// If set this handler will be called at appropriate times to highlight
	/// the drop destination view, as the mouse enters and leaves the view.
	
	var highlightViewHandler:((Bool)->Void)? { set get }

    /// The Progress object for the current download/copy operation
	
    var progress:Progress? { set get }
    
    /// The start time of a download/copy operation
	
    var startTime:CFAbsoluteTime { set get }
    
    /// KVO observers
	
	var observers:[Any] { set get }
}

	
//----------------------------------------------------------------------------------------------------------------------


// MARK: -
	
extension DraggingDestinationMixin
{

	/// Call this helper in the setup code of your view to configure it for receiving file drops
	
	public static func registerDragTypes(for view:NSView)
	{
        view.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        view.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - NSDraggingDestination
	
	
	@MainActor public func _draggingEntered(_ draggingInfo:NSDraggingInfo) -> NSDragOperation
    {
 		self.highlightViewHandler?(true)
		return .copy
    }

	@MainActor public func _draggingExited(_ draggingInfo:NSDraggingInfo?)
    {
 		self.highlightViewHandler?(false)
    }

	@MainActor public func _performDragOperation(_ draggingInfo:NSDraggingInfo) -> Bool
	{
		return self.receiveDroppedFiles(with:draggingInfo)
 	}

	@MainActor public func _concludeDragOperation(_ draggingInfo:NSDraggingInfo?)
    {
 		self.highlightViewHandler?(false)
    }


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Receiving Files
	
	
	/// Retrieves dragged files from the dragging pasteboard in of several datatypes. Whichever type
	/// has the highest priority will be processed, the other types will be ignored.
	
	@MainActor public func receiveDroppedFiles(with draggingInfo:NSDraggingInfo) -> Bool
	{
        let options:[NSPasteboard.ReadingOptionKey:Any] =
        [
			.urlReadingFileURLsOnly : true
		]
		
		// First look for native Object instances. This is the preferred datatype, because the native
		// Objects provide the best experience, as they carry a lot of metadata.

		if let identifiers = draggingInfo.draggingPasteboard.readObjects(forClasses:[NSString.self], options:options) as? [String], !identifiers.isEmpty
		{
			let objects = identifiers.compactMap { Object.draggedObject(for:$0) }
			let progress = self.prepareProgress(with:objects.count)

			Task
			{
				for object in objects
				{
					progress.becomeCurrent(withPendingUnitCount:1)
					await self.receiveObject(object)
					progress.resignCurrent()
				}
			}

			return true
			
//			return self.receivedItems(objects)
//			{
//				self.receiveObject($0)
//			}
		}
		
		// If the previous step failed, then look for dragged file URLs instead, e.g. a drag from Finder.
		// In this case we will only get the file URLs, without any accompagning metadata.
		
		if let urls = draggingInfo.draggingPasteboard.readObjects(forClasses:[NSURL.self], options:options) as? [URL], !urls.isEmpty
		{
			let progress = self.prepareProgress(with:urls.count)

			Task
			{
				for url in urls
				{
					progress.becomeCurrent(withPendingUnitCount:1)
					await self.receiveFile(with:url)
					progress.resignCurrent()
				}
			}

			return true
//			return self.receivedItems(urls)
//			{
//				self.receiveFile(with:$0)
//			}
		}

		// Nothing found
		
		return false
	}


	/// This generic function receive a list of Items (generic type) and calls the receiveHandler for each item.
	/// If this process takes a while a progress bar will be displayed automatically.
	
	private func receivedItems<Item>(_ items:[Item], progress:Progress, receiveHandler:(Item) async -> Void) async
	{
		guard !items.isEmpty else { return }

//		// Open a progress bar
//
//		let progress = self.prepareProgress(with:items.count)

		// Iterate over all dragged items and call the receiveHandler

		for item in items
		{
			progress.becomeCurrent(withPendingUnitCount:1)
			await receiveHandler(item)
			progress.resignCurrent()
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Receives an Object by waiting for the localFileURL in a background Task. The receiveFileHandler will
	/// be called on the main thread once the local file is available.
	
	private func receiveObject(_ object:Object?) async
	{
		guard let object = object else { return }
		let identifier = object.identifier

		logDragAndDrop.debug {"\(Self.self).\(#function)  object=\(object)  identifier=\(identifier)"}
		
		do
		{
			let url = try await object.localFileURL
			await MainActor.run { self.receiveFileHandler?(url,object,nil) }
		}
		catch let error
		{
			logDragAndDrop.error {"\(Self.self).\(#function) ERROR \(error)"}
			await MainActor.run { self.receiveFileHandler?(nil,nil,error) }
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Receives a local file. The receiveFileHandler is called immediately, as no background work is necessary.
	
	private func receiveFile(with url:URL) async
	{
		guard url.isFileURL else { return }

		logDragAndDrop.debug {"\(Self.self).\(#function)  url=\(url)"}
		
//		Progress.globalParent?.becomeCurrent(withPendingUnitCount:1)
		self.receiveFileHandler?(url,nil,nil)
//		Progress.globalParent?.resignCurrent()
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


//	private func receiveFile(with receiver:NSFilePromiseReceiver)
//	{
//		logDragAndDrop.debug {"\(Self.self).\(#function) promise = \(receiver)"}
//
//		let tmpFolder = URL(fileURLWithPath:NSTemporaryDirectory())
//		
//		receiver.receivePromisedFiles(atDestination:tmpFolder, options:[:], operationQueue:Object.promiseQueue)
//		{
//			url,error in
//
//			if let error = error
//			{
//				logDragAndDrop.error {"\(Self.self).\(#function) ERROR \(error)"}
//				DispatchQueue.main.async { self.receiveFileHandler?(nil,nil,error) }
//			}
//			else
//			{
//				logDragAndDrop.debug {"\(Self.self).\(#function) RECEIVED \(url)"}
//				DispatchQueue.main.async { self.receiveFileHandler?(url,nil,nil) }
//			}
//		}
//	}
	
	
	/// Downloads a promised file and copies it to the destination folder
	
//	private func copyFile(with receiver:NSFilePromiseReceiver)
//	{
//		receiver.receivePromisedFiles(atDestination:self.folderURL, options:[:], operationQueue:self.queue)
//		{
//			url,error in
//
//			if let error = error
//			{
//				logDragAndDrop.error {"\(Self.self).\(#function) ERROR \(error)"}
//			}
//			else
//			{
//				logDragAndDrop.debug {"\(Self.self).\(#function) RECEIVED \(url)"}
//			}
//		}
//	}
	
	
	/// Copies the specified file to the destination folder
	
//	private func copyFile(at srcURL:URL)
//	{
//		// Unfortunately FileManager doesn't support NSProgress, so we have to fake it here
//		
////		let childProgress = Progress(totalUnitCount:1)
////		Progress.globalParent?.addChild(childProgress, withPendingUnitCount:1)
////		defer { childProgress.completedUnitCount = 1 }
//		
//		// Link or copy the file to the folder
//		
//		let dstURL = self.folderURL.appendingPathComponent(srcURL.lastPathComponent)
//		
//		do
//		{
//			try FileManager.default.linkItem(at:srcURL, to:dstURL)
//		}
//		catch
//		{
//			do
//			{
//				try FileManager.default.copyItem(at:srcURL, to:dstURL)
//			}
//			catch
//			{
//				logDragAndDrop.error {"\(Self.self).\(#function) ERROR \(error)"}
//			}
//		}
//	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Progress
	
	
	/// Creates a root Progress object with the specified totalUnitCount
	
	private func prepareProgress(with count:Int) -> Progress
	{
		// Create root Progress
		
		let progress = Progress(totalUnitCount:Int64(count))
		progress.cancellationHandler = { [weak self] in self?.cancel() }
		self.progress = progress
		Progress.globalParent = progress

		// Store starting time
		
		self.startTime = CFAbsoluteTimeGetCurrent()
		
		// Register KVO observers
		
		self.observers = []
		
		self.observers += KVO(object:progress, keyPath:"fractionCompleted", options:[.new])
		{
			[weak self] _,_ in
			guard let self = self else { return }
			let fraction = progress.fractionCompleted
			self.updateProgress(fraction)
			if fraction >= 0.99 { self.hideProgress() }
		}
		
		BXProgressWindowController.shared.cancelHandler =
		{
			[weak self] in
			self?.cancel()
			self?.hideProgress()
		}

		return progress
	}
	
	
	/// Update the progress UI with the specified fraction
	
	private func updateProgress(_ fraction:Double)
	{
		DispatchQueue.main.asyncIfNeeded
		{
			let now = CFAbsoluteTimeGetCurrent()
			let dt = now - self.startTime
			let percent = Int(fraction*100)

			BXProgressWindowController.shared.title = "Copying Media Files"
			BXProgressWindowController.shared.value = fraction
			
			if !BXProgressWindowController.shared.isVisible && dt>1.0 && fraction<0.8
			{
				logDragAndDrop.debug {"\(Self.self).\(#function)  show progress window"}
				BXProgressWindowController.shared.show()
			}

			logDragAndDrop.verbose {"\(Self.self).\(#function)  progress=\(percent)%%  duration=\(dt)s"}
		}
	}
	
	
	/// Hides the progress UI
	
	private func hideProgress()
	{
		DispatchQueue.main.asyncIfNeeded
		{
			logDragAndDrop.debug {"\(Self.self).\(#function)"}
			
			BXProgressWindowController.shared.hide()
		
			Progress.globalParent = nil
			self.progress = nil
			self.observers = []
		}
	}


	/// Cancels the currently running download/copy operation
	
	public func cancel()
	{
		logDragAndDrop.debug {"\(Self.self).\(#function)"}
		self.progress?.cancel()
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
