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

import AppKit


//----------------------------------------------------------------------------------------------------------------------


public class FileDropDestination : NSObject,NSDraggingDestination
{
	/// Dropped files will be copied to this destination folder
	
	private var folderURL:URL
	
	/// If set this handler will be called at appropriate times to highlight or unhighlight the drop destination
	/// view, as the mouse moves in and out
	
	public var highlightDropTargetHandler:((Bool)->Void)? = nil
    
    /// File downloading and copying will take place on this background queue
	
	private let workQueue:OperationQueue =
	{
		let providerQueue = OperationQueue()
		providerQueue.qualityOfService = .userInitiated
		return providerQueue
	}()
    

//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new FileDropDestination
	
	init(folderURL:URL)
	{
		self.folderURL = folderURL
	}


	/// Call this helper in the setup code of your view to configure it for receiving file drops
	
	class func registerDragTypes(for view:NSView)
	{
        view.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        view.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - NSDraggingDestination
	
	
	public func draggingEntered(_ sender:NSDraggingInfo) -> NSDragOperation
    {
 		self.highlightDropTargetHandler?(true)
		return .copy
    }


    public func draggingExited(_ sender:NSDraggingInfo?)
    {
 		self.highlightDropTargetHandler?(false)
    }


	public func concludeDragOperation(_ sender: NSDraggingInfo?)
    {
 		self.highlightDropTargetHandler?(false)
    }


	public func performDragOperation(_ sender:NSDraggingInfo) -> Bool
	{
		self.copyDroppedFiles(sender)
        return true
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Helpers
	
	
	/// Copies dropped files to the destination folder. In the case of NSFilePromiseProvider, the file may
	/// have to be downloaded first.
	
	private func copyDroppedFiles(_ draggingInfo:NSDraggingInfo)
	{
		let classes =
		[
			NSFilePromiseReceiver.self,
			NSURL.self
		]

        let searchOptions:[NSPasteboard.ReadingOptionKey:Any] =
        [
            .urlReadingFileURLsOnly:true,
        ]

        draggingInfo.enumerateDraggingItems(options:[], for:nil, classes:classes, searchOptions:searchOptions)
        {
			draggingItem,_,_ in
			
			if let srcURL = draggingItem.item as? URL
			{
				self.copyFile(at:srcURL)
			}
			else if let receiver = draggingItem.item as? NSFilePromiseReceiver
			{
				self.copyFile(with:receiver)
			}
        }
	}


	/// Downloads a promised file and copies it to the destination folder
	
	private func copyFile(with receiver:NSFilePromiseReceiver)
	{
		receiver.receivePromisedFiles(atDestination:self.folderURL, options:[:], operationQueue:self.workQueue)
		{
			url,error in
			print(url)
		}
	}
	
	
	/// Copies the specified file to the destination folder
	
	private func copyFile(at srcURL:URL)
	{
		let dstURL = self.folderURL.appendingPathComponent(srcURL.lastPathComponent)
		
		do
		{
			try FileManager.default.linkItem(at:srcURL, to:dstURL)
		}
		catch
		{
			do
			{
				try FileManager.default.copyItem(at:srcURL, to:dstURL)
			}
			catch
			{
				print(error)
			}
		}
	}

}


//----------------------------------------------------------------------------------------------------------------------


#endif
