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


public struct DropDestinationView : NSViewRepresentable
{
	public typealias NSViewType = _DropDestinationView

	public var destinationFolderURL:URL
	
	public func makeNSView(context:Context) -> _DropDestinationView
	{
		let view = _DropDestinationView(frame:.zero)
		view.destinationFolderURL = self.destinationFolderURL
		return view
	}
	
	public func updateNSView(_ view:_DropDestinationView, context:Context)
	{
		view.destinationFolderURL = self.destinationFolderURL
	}
}


//----------------------------------------------------------------------------------------------------------------------


public class _DropDestinationView : NSView, FileDropDestinationMixin
{
	public var destinationFolderURL:URL? = nil

	private var dropTargetLayer:CALayer? = nil
	
//	internal lazy var workQueue:OperationQueue =
//    {
//        let providerQueue = OperationQueue()
//        providerQueue.qualityOfService = .userInitiated
//        return providerQueue
//    }()
    
    
//----------------------------------------------------------------------------------------------------------------------


	override init(frame:NSRect)
	{
		super.init(frame:frame)

        self.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        self.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
	}
	
	
	required init?(coder: NSCoder)
	{
		fatalError("Not implmented")
	}


//----------------------------------------------------------------------------------------------------------------------


	override public func draggingEntered(_ sender:NSDraggingInfo) -> NSDragOperation
    {
		return mixin_draggingEntered(sender)
    }


    override public func draggingExited(_ sender:NSDraggingInfo?)
    {
		mixin_draggingExited(sender)
    }


    override public func concludeDragOperation(_ sender: NSDraggingInfo?)
    {
		mixin_concludeDragOperation(sender)
    }


	override public func performDragOperation(_ sender:NSDraggingInfo) -> Bool
	{
		return mixin_performDragOperation(sender)
	}
	
	
//----------------------------------------------------------------------------------------------------------------------

	
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
}


//----------------------------------------------------------------------------------------------------------------------


@objc protocol FileDropDestinationMixin : NSDraggingDestination
{
	var destinationFolderURL:URL? { set get }
//	var workQueue:OperationQueue { get }
	func setHighlighted(_ state:Bool)
}

extension FileDropDestinationMixin
{

//	func registerDragTypes()
//	{
//        self.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
//        self.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
//	}
	
	public func mixin_draggingEntered(_ sender:NSDraggingInfo) -> NSDragOperation
    {
 		self.setHighlighted(true)
		return .copy
    }


    public func mixin_draggingExited(_ sender:NSDraggingInfo?)
    {
  		self.setHighlighted(false)
    }
	
	
    public func mixin_concludeDragOperation(_ sender: NSDraggingInfo?)
    {
 		self.setHighlighted(false)
    }
    
    
	public func mixin_performDragOperation(_ sender:NSDraggingInfo) -> Bool
	{
		guard let folderURL = destinationFolderURL else { return false }
		
		let classes =
		[
			NSFilePromiseReceiver.self,
			NSURL.self
		]

        let searchOptions:[NSPasteboard.ReadingOptionKey:Any] =
        [
            .urlReadingFileURLsOnly:true,
        ]

        sender.enumerateDraggingItems(options:[], for:nil, classes:classes, searchOptions:searchOptions)
        {
			(draggingItem, _, _) in
			
            switch draggingItem.item
            {
				case let filePromiseReceiver as NSFilePromiseReceiver:
				
				filePromiseReceiver.receivePromisedFiles(atDestination:folderURL, options:[:], operationQueue:workQueue)
                {
					url,error in
					print(url)
                }
                
				case let srcURL as URL:
				
					let dstURL = folderURL.appendingPathComponent(srcURL.lastPathComponent)
					self.copy(from:srcURL, to:dstURL)
					
				default: break
            }
        }
        
        return true
	}


	func copy(from srcURL:URL, to dstURL:URL)
	{
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


fileprivate let workQueue:OperationQueue =
{
	let providerQueue = OperationQueue()
	providerQueue.qualityOfService = .userInitiated
	return providerQueue
}()
    
    
//----------------------------------------------------------------------------------------------------------------------
