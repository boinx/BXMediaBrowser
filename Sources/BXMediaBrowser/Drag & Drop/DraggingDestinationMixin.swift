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


public class DropItem
{
	/// The URL of the dropped file
	
	var url:URL? = nil
	
	/// For in-app drag & drop the reference to the Object is available. In this case you can access additional metadata
	
	var object:Object? = nil
	
	/// Any error that might have occured while processing this item
	
	var error:Error? = nil
	
	/// Creates a new DropItem
	
	public init(url:URL? = nil, object:Object? = nil, error:Error? = nil)
	{
		self.url = url
		self.object = object
		self.error = error
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: -
	
public protocol DraggingDestinationMixin : DraggingProgressMixin
{
	/// This handler is called once for each received item.
	
	var processFileHandler:ProcessFileHandler? { set get }
	
	typealias ProcessFileHandler = (DropItem) throws -> Void

	/// This handler is called after the asynchronous and concurrent receiving has completed. The array of DropItems maintains the original order.
	
	var completionHandler:CompletionHandler? { set get }
	
	typealias CompletionHandler = ([DropItem])->Void

	/// If set this handler will be called at appropriate times to highlight
	/// the drop destination view, as the mouse enters and leaves the view.
	
	var highlightViewHandler:((Bool)->Void)? { set get }
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
		return self.receiveItems(with:draggingInfo)
 	}

	@MainActor public func _concludeDragOperation(_ draggingInfo:NSDraggingInfo?)
    {
 		self.highlightViewHandler?(false)
    }


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Receiving Files
	
	
	/// Retrieves dragged files from the dragging pasteboard in of several datatypes. Whichever type
	/// has the highest priority will be processed, the other types will be ignored.
	
	@MainActor public func receiveItems(with draggingInfo:NSDraggingInfo) -> Bool
	{
		// First look for native Object instances. This is the preferred datatype, because the native
		// Objects provide the best experience, as they carry a lot of metadata.

		if let objects = draggingInfo.draggingPasteboard.mediaBrowserObjects
		{
			let items = objects.map { DropItem(object:$0) }
			let progress = self.prepareProgress(with:objects.count)

			Task
			{
				try await self.receiveItems(items, progress:progress)
				{
					item in
					
					if let object = item.object
					{
						let url = try await object.localFileURL
						item.url = url
						try self.processFileHandler?(item)
					}
				}
			}

			return true
		}
		
		// If the previous step failed, then look for dragged file URLs instead, e.g. a drag from Finder.
		// In this case we will only get the file URLs, without any accompagning metadata.
		
		if let urls = draggingInfo.draggingPasteboard.fileURLs
		{
			let progress = self.prepareProgress(with:urls.count)
			let items = urls.map { DropItem(url:$0) }

			Task
			{
				try await self.receiveItems(items, progress:progress)
				{
					item in
					try self.processFileHandler?(item)
				}
			}

			return true
		}

		// Nothing found
		
		return false
	}


	/// This generic function receives a list of DropItems and calls the receive closure for each item.
	/// If this async operation takes a while a progress bar will be displayed automatically.
	
	private func receiveItems(_ items:[DropItem], progress:Progress, receive:@escaping (DropItem) async throws -> Void) async throws
	{
		guard !items.isEmpty else { return }

		// Perform all downloads concurrently with a task group
		
		try await withThrowingTaskGroup(of:Void.self)
		{
			group in

			for item in items
			{
				group.addTask { try await receive(item) }
			}

			try await group.waitForAll() // Needed to silence compiler warning - see https://stackoverflow.com/questions/70078461/withthrowingtaskgroup-no-calls-to-throwing-functions-occur-within-try-expres
		}
	
		// Call completionHandler when all downloads are done
		
		await MainActor.run
		{
			self.completionHandler?(items)
			self.hideProgress()
		}
	}
	
}


//----------------------------------------------------------------------------------------------------------------------


#endif
