/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A generic NSCollectionViewItem that has an NSTextField and an enclosing NSBox
*/

import Cocoa

public class ImageCell : NSCollectionViewItem
{

    static let reuseIdentifier = NSUserInterfaceItemIdentifier("BXMediaBrowser.ImageCell")

	var object:Object!
	{
		didSet
		{
			self.setup()
			self.update()
		}
	}
	
	var observers:[Any] = []
	
	override public func loadView()
	{
		let rect = CGRect(x:0, y:0, width:120, height:80)
		let rect2 = CGRect(x:0, y:0, width:120, height:22)
		let view = NSView(frame:rect)
		view.wantsLayer = true
		
		let imageView = NSImageView(frame:rect)
		imageView.autoresizingMask = [.width,.height]
		imageView.imageScaling = .scaleProportionallyDown
		imageView.imageAlignment = .alignCenter
		view.addSubview(imageView)
		
		let textField = NSTextField(frame:rect2)
		textField.isEditable = false
		textField.isSelectable = false
		textField.isBordered = false
		textField.alignment = .center
		textField.font = NSFont.systemFont(ofSize:11)
		textField.autoresizingMask = [.width,.height]
		textField.backgroundColor = .clear
		view.addSubview(textField)
		
		self.view = view
		self.imageView = imageView
		self.textField = textField
		
		
	}
	
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

//		DispatchQueue.main.async
//		{
			if let thumbnail = object.thumbnailImage
			{
				let w = thumbnail.width
				let h = thumbnail.height
				let size = CGSize(width:w, height:h)
				
				self.imageView?.image = NSImage(cgImage:thumbnail, size:size)
			}
		
			self.textField?.stringValue = self.object.name
//		}
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
            updateSelectionHighlighting()
        }
    }

    override public var isSelected:Bool
    {
        didSet
        {
            updateSelectionHighlighting()
        }
    }

    private func updateSelectionHighlighting()
    {
        if !isViewLoaded
        {
            return
        }

        let showAsHighlighted =
			(highlightState == .forSelection) ||
            (isSelected && highlightState != .forDeselection) ||
            (highlightState == .asDropTarget)

//        textField?.textColor = showAsHighlighted ? .selectedControlTextColor : .labelColor
        
        self.view.layer?.backgroundColor = showAsHighlighted ?
			NSColor.blue.cgColor :
			NSColor.clear.cgColor
        
//        if let box = view as? NSBox
//        {
//            box.fillColor = showAsHighlighted ? .selectedControlColor : .gray
//        }
    }
}
