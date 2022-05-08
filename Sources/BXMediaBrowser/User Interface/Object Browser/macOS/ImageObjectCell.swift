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
import BXSwiftUI


//----------------------------------------------------------------------------------------------------------------------


open class ImageObjectCell : ObjectCell
{
    override open class var identifier:NSUserInterfaceItemIdentifier
    {
    	NSUserInterfaceItemIdentifier("BXMediaBrowser.ImageObjectViewController")
	}
	
	override open var nibName:NSNib.Name? { nil }

	override open var nibBundle:Bundle? { nil }

	override class var width:CGFloat { 120 }
	
	override class var height:CGFloat { 96 }
	
	override class var spacing:CGFloat { 10 }

	// Returns the minimum & maximum supported thumbnail size
	
	public static var minThumbnailSize:CGFloat { 70 } 	// ObjectRatingView requires this width without clipping
	public static var maxThumbnailSize:CGFloat { 320 }


//----------------------------------------------------------------------------------------------------------------------


	/// Builds the view hierarchy for a single cell
	
	override open func loadView()
	{
		self.view = ObjectView(frame:CGRect(x:0, y:0, width:120, height:96))
		self.view.translatesAutoresizingMaskIntoConstraints = false
		
		let imageView = NSImageView(frame:CGRect(x:0, y:16, width:120, height:80))
		imageView.image = Bundle.BXMediaBrowser.image(forResource:"thumbnail-placeholder")
		self.imageView = imageView
		self.view.addSubview(imageView)
		
		let textField = NSTextField(frame:CGRect(x:0, y:0, width:120, height:14))
		self.textField = textField
		self.view.addSubview(textField)
		
		let useCountView = NSTextField(frame:CGRect(x:98, y:74, width:18, height:18))
		self.useCountView = useCountView
		self.view.addSubview(useCountView)

		let ratingView = ObjectRatingView(frame: CGRect(x:0, y:0, width:70, height:14))
		self.ratingView = ratingView
		self.view.addSubview(ratingView)
		
		imageView.imageScaling = .scaleProportionallyUpOrDown
		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.leadingAnchor.constraint(equalTo:view.leadingAnchor, constant:0).isActive = true
		imageView.trailingAnchor.constraint(equalTo:view.trailingAnchor, constant:0).isActive = true
		imageView.topAnchor.constraint(equalTo:view.topAnchor, constant:0).isActive = true
		let bottom = imageView.bottomAnchor.constraint(equalTo:view.bottomAnchor, constant:-16)
		bottom.priority = NSLayoutConstraint.Priority(999)
		bottom.isActive = true

		textField.translatesAutoresizingMaskIntoConstraints = false
		textField.heightAnchor.constraint(equalToConstant:14).isActive = true
		textField.bottomAnchor.constraint(equalTo:view.bottomAnchor, constant:0).isActive = true
		textField.leadingAnchor.constraint(equalTo:view.leadingAnchor, constant:0).isActive = true
		textField.trailingAnchor.constraint(equalTo:view.trailingAnchor, constant:0).isActive = true
		self.setupTextField(textField, size:NSFont.smallSystemFontSize, alignment:.center, alpha:0.5)

		ratingView.translatesAutoresizingMaskIntoConstraints = false
		ratingView.heightAnchor.constraint(equalToConstant:14).isActive = true
		ratingView.bottomAnchor.constraint(equalTo:view.bottomAnchor, constant:1).isActive = true
		ratingView.widthAnchor.constraint(equalToConstant:70).isActive = true
		ratingView.centerXAnchor.constraint(equalTo:view.centerXAnchor, constant:0).isActive = true

		useCountView.cell = PillTextFieldCell()
		useCountView.textColor = .white
		useCountView.backgroundColor = NSColor(calibratedRed:0.0, green:0.5, blue:0.0, alpha:1.0)
		useCountView.font = NSFont.systemFont(ofSize:11, weight:.bold)
		useCountView.alignment = .center
		self.setupUseCountLayout()
		
		self.view.needsLayout = true
	}
	
	
	override open func setup()
	{
		super.setup()
		self.hasThumbnail = false
	}
	
	
	/// Redraws the cell by updating the thumbnail and name
	
	override public func redraw()
	{
		guard let object = object else { return }

		// Thumbnail
		
		let thumbnail = object.thumbnailImage
		let placeholder = Bundle.BXMediaBrowser.image(forResource:"thumbnail-placeholder")?.CGImage
		self.hasThumbnail = thumbnail != nil
		
		if let image = thumbnail ?? placeholder
		{
			let w = image.width
			let h = image.height
			let size = CGSize(width:w, height:h)
			self.imageView?.image = NSImage(cgImage:image, size:size)
			self.setupUseCountLayout()
		}
	
		// Name
		
		self.textField?.stringValue = object.displayName
		
		// Use count badge
		
		let n = StatisticsController.shared.useCount(for:object)
		self.useCountView?.stringValue = "\(n)"
		self.useCountView?.isHidden = n == 0

		// Gray out cell if Object is not enabled
		
		let isEnabled = self.isEnabled
		let alpha:Float = isEnabled ? 1.0 : 0.33

		self.imageView?.isEnabled = isEnabled
		self.textField?.isEnabled = isEnabled
		self.ratingView?.isEnabled = isEnabled
		self.imageView?.layer?.opacity = alpha
		self.textField?.layer?.opacity = 0.66 * alpha
		self.useCountView?.layer?.opacity = alpha
	}
	
	
	/// Sets a new tooltip on the cell
	
	override open func updateTooltip()
	{
		self.imageView?.removeAllToolTips()
		
		if let comment = self.object?.comment
		{
			self.imageView?.toolTip = comment
		}
	}


//----------------------------------------------------------------------------------------------------------------------


	// MARK: -
	
	private var hasThumbnail = false
	{
		didSet { self.updateHighlight() }
	}

    override public var isSelected:Bool
    {
        didSet { self.updateHighlight() }
    }

	override public var highlightState:NSCollectionViewItem.HighlightState
    {
        didSet { self.updateHighlight() }
    }

    private func updateHighlight()
    {
        guard isViewLoaded else { return }
		
		let isHilited = isEnabled && (isSelected || highlightState != .none)

		if let layer = self.imageView?.subviews.first?.layer
		{
			layer.borderWidth = isHilited ? 4.0 : 1.0
			layer.borderColor = isHilited ? NSColor.systemYellow.cgColor : self.strokeColor.cgColor
		}
    }
    
    private var strokeColor:NSColor
    {
		guard hasThumbnail else { return .clear }
		
		return self.view.effectiveAppearance.isDarkMode ?
			NSColor.white.withAlphaComponent(0.2) :
			NSColor.black.withAlphaComponent(0.2)
    }
}


//----------------------------------------------------------------------------------------------------------------------


// We do not want cell selection or drag & drop to work when clicking on the transparent cell background.
// Only the visible part of the thumbnail, should be the active area. For this reason we need to override
// hit-testing for the root view of the cell.

// Inspired by https://developer.apple.com/forums/thread/30023 and
// https://stackoverflow.com/questions/48765128/drag-selecting-in-nscollectionview-from-inside-of-items

class ImageThumbnailView : ObjectView
{
	override func hitTest(_ point:NSPoint) -> NSView?
	{
		let view = super.hitTest(point)
		
		// The NSImageView spans the entire area of the cell, but the thumbnail itself does not (due to different
		// aspect ratio it is fitted inside) so check the first subview of NSImageView (which displays the image
		// itself). Hopefully this woon't break in future OS releases.
		
		if let imageView = view as? NSImageView, let thumbnail = imageView.subviews.first
		{
			let p = thumbnail.convert(point, from:self.superview)
			if !NSPointInRect(p,thumbnail.bounds) { return nil }
		}
		
		// Exclude the textfield from hit testing
		
		if view is NSTextField
		{
			return nil
		}
		
		return view
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
