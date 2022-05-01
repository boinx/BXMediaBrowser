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

import SwiftUI


//----------------------------------------------------------------------------------------------------------------------


public struct FileDropDestinationView : NSViewRepresentable
{
	public typealias NSViewType = _FileDropDestinationView

	public var fileDropDestination:FolderDropDestination? = nil
	
	public init(with fileDropDestination:FolderDropDestination?)
	{
		self.fileDropDestination = fileDropDestination
	}
	
	public func makeNSView(context:Context) -> _FileDropDestinationView
	{
		let view = _FileDropDestinationView(frame:.zero)
		view.fileDropDestination = self.fileDropDestination
		return view
	}
	
	public func updateNSView(_ view:_FileDropDestinationView, context:Context)
	{
		view.fileDropDestination = self.fileDropDestination
	}
}


//----------------------------------------------------------------------------------------------------------------------


public class _FileDropDestinationView : NSView
{
	/// An externally supplied FileDropDestination helper object. This helper object implements the
	/// NSDraggingDestination for dropped files.
	
 	internal var fileDropDestination:FolderDropDestination? = nil
	{
		didSet
		{
			self.fileDropDestination?.highlightViewHandler = { [weak self] in self?.setHighlighted($0) }
		}
	}
	
	/// A CALayer that is responsible for displaying a highlight
	
	private var dropTargetLayer:CALayer? = nil
    
    
//----------------------------------------------------------------------------------------------------------------------


	/// Creates a new _FileDropDestinationView and configures it for receiving dropped files
	
	override init(frame:NSRect)
	{
		super.init(frame:frame)
		FolderDropDestination.registerDragTypes(for:self)
	}
	
	required init?(coder: NSCoder)
	{
		fatalError("Not implmented")
	}


//----------------------------------------------------------------------------------------------------------------------

	
	/// Creates the CALayer for thsi view and adds a sublayer for displaying the drop target highlight
	
	public override func makeBackingLayer() -> CALayer
	{
		let layer = super.makeBackingLayer()
		layer.masksToBounds = false
		
		let sublayer = CALayer()
		layer.addSublayer(sublayer)
		self.dropTargetLayer = sublayer
		
		return layer
	}
	
	
	/// Displays the highlight when the supplied state is true
	
	func setHighlighted(_ state:Bool)
	{
 		let frame = self.bounds.insetBy(dx:-200, dy:0)
		self.dropTargetLayer?.frame = frame
		self.layer?.masksToBounds = false

		self.dropTargetLayer?.backgroundColor = state ?
			NSColor.labelColor.withAlphaComponent(0.15).cgColor :
			NSColor.clear.cgColor
	}


//----------------------------------------------------------------------------------------------------------------------


	// Route the NSDraggingDestination delegate messages to the FileDropDestination helper object
	
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

#endif
