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
	
	/// This handler is called for each received media file.

	public var processFileHandler: ProcessFileHandler? = nil
	
	/// The completionHandler is called at the end once all files have been processed
	
	public var completionHandler: CompletionHandler? = nil
	
	/// If set this handler will be called at appropriate times to highlight
	/// the drop destination view, as the mouse enters and leaves the view.
	
	public var highlightViewHandler:((Bool)->Void)? = nil
    
    /// Returns true if dropping to this folder is allowed
	
    public private(set) var isEnabled = true
    
    /// The Progress object for the current download/copy operation
	
    public var progress:Progress? = nil
    
    /// KVO observers
	
	public var progressObserver:Any? = nil
    
    /// The start time of a download/copy operation
	
    public var progressStartTime:CFAbsoluteTime = .zero
	
    /// Returns the optional title for the download progress
	
	public var progressTitle:String? { nil }
	
    /// Returns the optional message for the download progress
	
	public var progressMessage:String? { nil }
	
	
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new FolderDropDestination
	
	public init(folderURL:URL)
	{
		self.folderURL = folderURL
		self.isEnabled = folderURL.isWritable && !folderURL.path.contains("/Library")
		
		super.init()
		
		self.processFileHandler =
		{
			[weak self] in try self?.copyFileToFolder(item:$0)
		}
		
		self.completionHandler =
		{
			items in
			logDragAndDrop.debug {"\(Self.self) finished copying \(items.count) files"}
		}
	}
	
	
	/// If the file originated in a different folder, it will be copied the to the destination folder.
		
	public func copyFileToFolder(item:DropItem) throws -> Void
	{
		guard item.error == nil else { return }
		guard let url = item.url else { return }

		let filename = url.lastPathComponent
		let dstURL = self.folderURL.appendingPathComponent(filename)
		guard url != dstURL else { return }
			
		try url.fastCopy(to:dstURL)
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - NSDraggingDestination
	
	
	@MainActor public func draggingEntered(_ draggingInfo:NSDraggingInfo) -> NSDragOperation
    {
		guard isEnabled else { return [] }
		return self._draggingEntered(draggingInfo)
    }

    @MainActor public func draggingExited(_ draggingInfo:NSDraggingInfo?)
    {
		self._draggingExited(draggingInfo)
    }

	@MainActor public func performDragOperation(_ draggingInfo:NSDraggingInfo) -> Bool
	{
		guard isEnabled else { return false }
		return self._performDragOperation(draggingInfo)
	}

	@MainActor public func concludeDragOperation(_ draggingInfo:NSDraggingInfo?)
    {
		self._concludeDragOperation(draggingInfo)
    }


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - NSCollectionViewDelegate
	
	@MainActor public func collectionView(_ collectionView:NSCollectionView, validateDrop draggingInfo:NSDraggingInfo, proposedIndexPath:AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation:UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation
	{
		guard isEnabled else { return [] }

		let n = collectionView.numberOfItems(inSection:0)
        dropOperation.pointee = .before
        proposedIndexPath.pointee = NSIndexPath(index:n)
		return [.copy]
	}


	@MainActor public func collectionView(_ collectionView:NSCollectionView, acceptDrop draggingInfo:NSDraggingInfo, indexPath:IndexPath, dropOperation:NSCollectionView.DropOperation) -> Bool
	{
		guard isEnabled else { return false }
		return self.receiveItems(with:draggingInfo)
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
