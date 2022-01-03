/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A generic NSCollectionViewItem that has an NSTextField and an enclosing NSBox
*/

import Cocoa

public class ImageCell : NSCollectionViewItem
{

    static let reuseIdentifier = NSUserInterfaceItemIdentifier("BXMediaBrowser.ImageCell")

	override open var nibName: NSNib.Name?
    {
		"ImageCell"
	}

	override open var nibBundle: Bundle?
    {
		Bundle.module
	}

	var object:Object!
	{
		didSet
		{
			self.setup()
			self.update()
		}
	}
	
	var observers:[Any] = []
	
//	override public func loadView()
//	{
//		let w:CGFloat = 120
//		let h:CGFloat = 80
//		let d:CGFloat = 5
//		let t:CGFloat = 22
//
//		let rect1 = CGRect(x:0, y:0, width:w, height:h+t)
//		let rect2 = CGRect(x:0, y:t, width:w, height:h)
//		let rect3 = CGRect(x:0, y:5, width:w, height:t)
//		let view = NSView(frame:rect1)
//		view.wantsLayer = true
//		view.layer?.borderColor = NSColor.green.cgColor
//		view.layer?.borderWidth = 1
//
//		let imageView = NSImageView(frame:rect2)
//		imageView.autoresizingMask = [.width,.height]
//		imageView.imageScaling = .scaleProportionallyDown
//		imageView.imageAlignment = .alignCenter
//		view.addSubview(imageView)
//
//		let textField = NSTextField(frame:rect3)
//		textField.isEditable = false
//		textField.isSelectable = false
//		textField.isBordered = false
//		textField.alignment = .center
//		textField.font = NSFont.systemFont(ofSize:11)
//		textField.autoresizingMask = [.width,.height]
//		textField.backgroundColor = .clear
//		view.addSubview(textField)
//
//		self.view = view
//		self.imageView = imageView
//		self.textField = textField
//	}
	
	func setup()
	{
		guard let object = object else { return }

		self.observers = []
		
		self.observers += object.$thumbnailImage
			.receive(on:RunLoop.main)
			.sink
			{
				_ in
				self.update()
			}
		
		self.loadIfNeeded()
	}
	
	func update()
	{
		guard let object = object else { return }

		if let thumbnail = object.thumbnailImage
		{
			let w = thumbnail.width
			let h = thumbnail.height
			let size = CGSize(width:w, height:h)
			self.imageView?.image = NSImage(cgImage:thumbnail, size:size)
		}
	
		self.textField?.stringValue = self.object.name
	}
	
    func loadIfNeeded()
    {
		if object.thumbnailImage == nil || object.metadata == nil
		{
			object.load()
		}
    }

	override public var highlightState: NSCollectionViewItem.HighlightState
    {
        didSet
        {
            updateSelection()
        }
    }

    override public var isSelected:Bool
    {
        didSet
        {
            updateSelection()
        }
    }

    private func updateSelection()
    {
        if !isViewLoaded
        {
            return
        }

		let isHilited = self.isSelected	|| self.highlightState != .none

		if let layer = self.imageView?.subviews.first?.layer
		{
			layer.borderWidth = isHilited ? 4.0 : 0.0
			layer.borderColor = isHilited ? NSColor.systemYellow.cgColor : NSColor.clear.cgColor
		}
    }
}
