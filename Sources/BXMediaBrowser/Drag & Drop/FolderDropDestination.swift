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


public class FolderDropDestination : NSObject, NSDraggingDestination, DraggingDestinationMixin
{
	/// Dropped files will be copied to this destination folder
	
	private var folderURL:URL
	
	/// This handler is called for each received media file. In case of in-app drags,
	/// the optional Object instance may also be supplied to the handler.

	public var receiveFileHandler:((URL?,Object?,Error?)->Void)? = nil
	
	/// If set this handler will be called at appropriate times to highlight
	/// the drop destination view, as the mouse enters and leaves the view.
	
	public var highlightViewHandler:((Bool)->Void)? = nil
    
    /// The Progress object for the current download/copy operation
	
    public var progress:Progress? = nil
    
    /// The start time of a download/copy operation
	
    public var startTime:CFAbsoluteTime = .zero
    
    /// KVO observers
	
	public var observers:[Any] = []
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new FolderDropDestination
	
	public init(folderURL:URL)
	{
		self.folderURL = folderURL
		
		super.init()
		
		self.receiveFileHandler =
		{
			[weak self] url,object,error in self?.copyFileToFolder(url:url, object:object, error:error)
		}
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - NSDraggingDestination
	
	
	public func draggingEntered(_ draggingInfo:NSDraggingInfo) -> NSDragOperation
    {
		self._draggingEntered(draggingInfo)
    }

    public func draggingExited(_ draggingInfo:NSDraggingInfo?)
    {
		self._draggingExited(draggingInfo)
    }

	public func performDragOperation(_ draggingInfo:NSDraggingInfo) -> Bool
	{
		return self._performDragOperation(draggingInfo)
	}

	public func concludeDragOperation(_ draggingInfo:NSDraggingInfo?)
    {
		self._concludeDragOperation(draggingInfo)
    }


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - NSCollectionViewDelegate
	
	@MainActor public func collectionView(_ collectionView:NSCollectionView, validateDrop draggingInfo:NSDraggingInfo, proposedIndexPath:AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation:UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation
	{
		let n = collectionView.numberOfItems(inSection:0)
        dropOperation.pointee = .before
        proposedIndexPath.pointee = NSIndexPath(index:n)
		return [.copy]
	}


	@MainActor public func collectionView(_ collectionView:NSCollectionView, acceptDrop draggingInfo:NSDraggingInfo, indexPath:IndexPath, dropOperation:NSCollectionView.DropOperation) -> Bool
	{
		return self.reveiceDroppedFiles(with:draggingInfo)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Copying


	public func copyFileToFolder(url:URL?, object:Object?, error:Error?)
	{
		// If an error has occured, just log the error
		
		if let error = error
		{
			logDragAndDrop.error {"\(Self.self).\(#function) ERROR \(error)"}
		}
		
		// Otherwise copy the file to the destination folder
		
		else if let url = url
		{
			let filename = url.lastPathComponent
			let dstURL = self.folderURL.appendingPathComponent(filename)
			
			do
			{
				try url.fastCopy(to:dstURL)
			}
			catch let error
			{
				logDragAndDrop.error {"\(Self.self).\(#function) ERROR \(error)"}
			}
		}
	}


//	/// Copies dropped files to the destination folder. In the case of NSFilePromiseProvider, the file may
//	/// have to be downloaded first.
//
//	private func copyDroppedFiles(_ draggingInfo:NSDraggingInfo)
//	{
//		// Get the dropped files from the dragging pasteboard
//
//        let options:[NSPasteboard.ReadingOptionKey:Any] = [ .urlReadingFileURLsOnly:true ]
//		let identifiers = draggingInfo.draggingPasteboard.readObjects(forClasses:[NSString.self], options:options)?.compactMap { $0 as? String }
//		let urls = draggingInfo.draggingPasteboard.readObjects(forClasses:[NSURL.self], options:options)?.compactMap { $0 as? URL }
//		let promises = draggingInfo.draggingPasteboard.readObjects(forClasses:[NSFilePromiseReceiver.self], options:options)?.compactMap { $0 as? NSFilePromiseReceiver }
//
//		// First check for native Object instances (in-app drag & drop)
//
//		if let identifiers = identifiers, identifiers.count > 0
//		{
//			let progress = self.prepareProgress(with:identifiers.count)
//
//			for identifier in identifiers
//			{
//				progress.becomeCurrent(withPendingUnitCount:1)
//				print("identifier = \(identifier)")
//				progress.resignCurrent()
//			}
//		}
//
//		// Next check for dragged URLs (e.g. from Finder)
//
//		else if let urls = urls, urls.count > 0
//		{
//			let progress = self.prepareProgress(with:urls.count)
//
//			for url in urls
//			{
//				progress.becomeCurrent(withPendingUnitCount:1)
//				print("url = \(url)")
//				progress.resignCurrent()
//			}
//		}
//
//		// Finally check for NSFilePromiseReceivers
//
//		else if let promises = promises, promises.count > 0
//		{
//			let progress = self.prepareProgress(with:promises.count)
//
//			for promise in promises
//			{
//				progress.becomeCurrent(withPendingUnitCount:1)
//				print("promise = \(promise)")
//				progress.resignCurrent()
//			}
//		}
//
////        let options:[NSPasteboard.ReadingOptionKey:Any] = [ .urlReadingFileURLsOnly:true ]
////		let classes = [ NSFilePromiseReceiver.self, NSURL.self, NSString.self ]
////		let files = draggingInfo.draggingPasteboard.readObjects(forClasses:classes, options:options) ?? []
////
////		// Prepare progress observing
////
////		let progress = self.prepareProgress(with:files.count)
////
////		// Iterate through all NSDraggingItems and copy dropped files
////
////		for file in files
////		{
////			progress.becomeCurrent(withPendingUnitCount:1)
////
////			if let string = file as? String
////			{
////				print("Dropped string = '\(string)'")
////			}
////			else if let srcURL = file as? URL
////			{
////				self.copyFile(at:srcURL)
////			}
////			else if let receiver = file as? NSFilePromiseReceiver
////			{
////				self.copyFile(with:receiver)
////			}
////
////			progress.resignCurrent()
////		}
//	}
//
//
//	/// Downloads a promised file and copies it to the destination folder
//
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
//
//
//	/// Copies the specified file to the destination folder
//
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
}


//----------------------------------------------------------------------------------------------------------------------


#endif
