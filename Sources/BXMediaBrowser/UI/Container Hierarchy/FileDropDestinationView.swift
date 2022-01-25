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


import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


public struct FileDropDestinationView : NSViewRepresentable
{
	public typealias NSViewType = _FileDropDestinationView

	public var folderURL:URL
	
	public func makeNSView(context:Context) -> _FileDropDestinationView
	{
		let view = _FileDropDestinationView(frame:.zero)
		view.folderURL = self.folderURL
		return view
	}
	
	public func updateNSView(_ view:_FileDropDestinationView, context:Context)
	{
		view.folderURL = self.folderURL
	}
}


//----------------------------------------------------------------------------------------------------------------------


public class _FileDropDestinationView : NSView
{
	public var folderURL:URL? = nil
	{
		didSet { self.configureFileDropDestination() }
	}
	
 	private var fileDropDestination:FileDropDestination? = nil

	private var dropTargetLayer:CALayer? = nil
    
    
	override init(frame:NSRect)
	{
		super.init(frame:frame)
		FileDropDestination.registerDragTypes(for:self)
	}
	
	
	required init?(coder: NSCoder)
	{
		fatalError("Not implmented")
	}


	private func configureFileDropDestination()
	{
		if let url = self.folderURL
		{
			self.fileDropDestination = FileDropDestination(folderURL:url)
			self.fileDropDestination?.highlightDropTargetHandler = { [weak self] in self?.setHighlighted($0) }
		}
		else
		{
			self.fileDropDestination = nil
		}
	}
	
	
	public override func makeBackingLayer() -> CALayer
	{
		let layer = super.makeBackingLayer()
		layer.masksToBounds = false
		
		let sublayer = CALayer()
		layer.addSublayer(sublayer)
		self.dropTargetLayer = sublayer
		
		return layer
	}
	
	
	func setHighlighted(_ state:Bool)
	{
 		let frame = self.bounds.insetBy(dx:-200, dy:0)
		self.dropTargetLayer?.frame = frame
		self.layer?.masksToBounds = false

		self.dropTargetLayer?.backgroundColor = state ?
			NSColor.labelColor.withAlphaComponent(0.15).cgColor :
			NSColor.clear.cgColor
	}


	override public func draggingEntered(_ sender:NSDraggingInfo) -> NSDragOperation
    {
		return self.fileDropDestination?.draggingEntered(sender) ?? []
		
    }


    override public func draggingExited(_ sender:NSDraggingInfo?)
    {
		self.fileDropDestination?.draggingExited(sender)
    }


	override public func performDragOperation(_ sender:NSDraggingInfo) -> Bool
	{
		return self.fileDropDestination?.performDragOperation(sender) ?? false
	}


    override public func concludeDragOperation(_ sender: NSDraggingInfo?)
    {
		self.fileDropDestination?.concludeDragOperation(sender)
    }
}


//----------------------------------------------------------------------------------------------------------------------


//@objc protocol FileDropDestinationMixin : NSDraggingDestination
//{
//	var destinationFolderURL:URL? { set get }
//
//	func setHighlighted(_ state:Bool)
//}
//
//extension FileDropDestinationMixin
//{
//
//	func registerDragTypes(for view:NSView)
//	{
//        view.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
//        view.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
//	}
//
//	public func mixin_draggingEntered(_ sender:NSDraggingInfo) -> NSDragOperation
//    {
// 		self.setHighlighted(true)
//		return .copy
//    }
//
//
//    public func mixin_draggingExited(_ sender:NSDraggingInfo?)
//    {
//  		self.setHighlighted(false)
//    }
//
//
//    public func mixin_concludeDragOperation(_ sender: NSDraggingInfo?)
//    {
// 		self.setHighlighted(false)
//    }
//
//
//	public func mixin_performDragOperation(_ sender:NSDraggingInfo) -> Bool
//	{
//		guard let folderURL = destinationFolderURL else { return false }
//
//		let classes =
//		[
//			NSFilePromiseReceiver.self,
//			NSURL.self
//		]
//
//        let searchOptions:[NSPasteboard.ReadingOptionKey:Any] =
//        [
//            .urlReadingFileURLsOnly:true,
//        ]
//
//        sender.enumerateDraggingItems(options:[], for:nil, classes:classes, searchOptions:searchOptions)
//        {
//			(draggingItem, _, _) in
//
//            switch draggingItem.item
//            {
//				case let filePromiseReceiver as NSFilePromiseReceiver:
//
//				filePromiseReceiver.receivePromisedFiles(atDestination:folderURL, options:[:], operationQueue:workQueue)
//                {
//					url,error in
//					print(url)
//                }
//
//				case let srcURL as URL:
//
//					let dstURL = folderURL.appendingPathComponent(srcURL.lastPathComponent)
//					self.copy(from:srcURL, to:dstURL)
//
//				default: break
//            }
//        }
//
//        return true
//	}
//
//
//	func copy(from srcURL:URL, to dstURL:URL)
//	{
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
//				print(error)
//			}
//		}
//	}
//}
//
//
//fileprivate let workQueue:OperationQueue =
//{
//	let providerQueue = OperationQueue()
//	providerQueue.qualityOfService = .userInitiated
//	return providerQueue
//}()
    
    
//----------------------------------------------------------------------------------------------------------------------
