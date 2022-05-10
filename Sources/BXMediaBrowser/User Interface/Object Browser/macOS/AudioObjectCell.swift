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
import AppKit


//----------------------------------------------------------------------------------------------------------------------


open class AudioObjectCell : ObjectCell
{
	// Outlets
	
    @IBOutlet weak open var nameField: NSTextField?
    @IBOutlet weak open var metadataField: NSTextField?
    @IBOutlet weak open var durationField: NSTextField?
    @IBOutlet weak open var sizeField: NSTextField?


//----------------------------------------------------------------------------------------------------------------------


	// The reuse identifier for this CollectionView cell
	
    override open class var identifier:NSUserInterfaceItemIdentifier
    {
    	NSUserInterfaceItemIdentifier("BXMediaBrowser.AudioObjectViewController")
	}
	
	override open var nibName:NSNib.Name? { nil }

	override open var nibBundle:Bundle? { nil }

	override class var width:CGFloat { 0 }	// width 0 means full width of the view
	
	override class var height:CGFloat { 46 }
	
	override class var spacing:CGFloat { 0 }

	// Set whenever playback status changes
	
	var isPlaying = false
	{
		didSet { redraw() }
	}
	
	/// Returns true if this cell displays a warning icon
	
	private var showsWarningIcon = false
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Setup
	

	/// Builds the view hierarchy for a single cell
	
	override open func loadView()
	{
		self.view = ObjectView(frame:CGRect(x:0, y:0, width:946, height:46))
		self.view.translatesAutoresizingMaskIntoConstraints = false
		
		let imageView = NSImageView(frame:CGRect(x:6, y:7, width:32, height:32))
		imageView.imageScaling = .scaleProportionallyUpOrDown
		self.imageView = imageView
		self.view.addSubview(imageView)
		
		let nameField = NSTextField(frame:CGRect(x:40, y:24, width:4, height:16))
		self.nameField = nameField
		self.view.addSubview(nameField)
		
		let ratingView = ObjectRatingView(frame: CGRect(x:46, y:24, width:90, height:16))
		self.ratingView = ratingView
		self.view.addSubview(ratingView)
		
		let durationField = NSTextField(frame:CGRect(x:924, y:24, width:4, height:16))
		self.durationField = durationField
		self.view.addSubview(durationField)
		
		let metadataField = NSTextField(frame:CGRect(x:40, y:6, width:880, height:14))
		self.metadataField = metadataField
		self.view.addSubview(metadataField)
		
		let sizeField = NSTextField(frame:CGRect(x:924, y:6, width:4, height:14))
		self.sizeField = sizeField
		self.view.addSubview(sizeField)
		
		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.leadingAnchor.constraint(equalTo:view.leadingAnchor, constant:6).isActive = true
		imageView.topAnchor.constraint(equalTo:view.topAnchor, constant:7).isActive = true
		imageView.widthAnchor.constraint(equalToConstant:32).isActive = true
		imageView.heightAnchor.constraint(equalToConstant:32).isActive = true
		imageView.imageScaling = .scaleProportionallyDown

		nameField.translatesAutoresizingMaskIntoConstraints = false
		nameField.topAnchor.constraint(equalTo:view.topAnchor, constant:6).isActive = true
		nameField.leadingAnchor.constraint(equalTo:imageView.trailingAnchor, constant:4).isActive = true
		nameField.widthAnchor.constraint(greaterThanOrEqualToConstant:32).isActive = true
		nameField.heightAnchor.constraint(equalToConstant:16).isActive = true
		self.setupTextField(nameField, size:NSFont.systemFontSize, alignment:.left)

		ratingView.translatesAutoresizingMaskIntoConstraints = false
		ratingView.topAnchor.constraint(equalTo:view.topAnchor, constant:7).isActive = true
		ratingView.leadingAnchor.constraint(equalTo:nameField.trailingAnchor, constant:4).isActive = true
		ratingView.heightAnchor.constraint(equalToConstant:16).isActive = true
		let width1 = ratingView.widthAnchor.constraint(equalToConstant:90)
		width1.priority = .defaultHigh
		width1.isActive = true

		durationField.translatesAutoresizingMaskIntoConstraints = false
		durationField.topAnchor.constraint(equalTo:view.topAnchor, constant:6).isActive = true
		durationField.leadingAnchor.constraint(greaterThanOrEqualTo:ratingView.trailingAnchor, constant:4).isActive = true
		durationField.trailingAnchor.constraint(equalTo:view.trailingAnchor, constant:-20).isActive = true
		durationField.heightAnchor.constraint(equalToConstant:16).isActive = true
		let width2 = durationField.widthAnchor.constraint(greaterThanOrEqualToConstant:60)
		width2.priority = .defaultHigh
		width2.isActive = true
		self.setupTextField(durationField, size:NSFont.systemFontSize, alignment:.right)
		durationField.isSelectable = false

		metadataField.translatesAutoresizingMaskIntoConstraints = false
		metadataField.topAnchor.constraint(equalTo:nameField.bottomAnchor, constant:4).isActive = true
		metadataField.leadingAnchor.constraint(equalTo:imageView.trailingAnchor, constant:4).isActive = true
		metadataField.widthAnchor.constraint(greaterThanOrEqualToConstant:32).isActive = true
		metadataField.heightAnchor.constraint(equalToConstant:14).isActive = true
		self.setupTextField(metadataField, size:NSFont.smallSystemFontSize, alignment:.left, alpha:0.5)

		sizeField.translatesAutoresizingMaskIntoConstraints = false
		sizeField.topAnchor.constraint(equalTo:nameField.bottomAnchor, constant:4).isActive = true
		sizeField.leadingAnchor.constraint(greaterThanOrEqualTo:metadataField.trailingAnchor, constant:2).isActive = true
		sizeField.heightAnchor.constraint(equalToConstant:14).isActive = true
		sizeField.trailingAnchor.constraint(equalTo:view.trailingAnchor, constant:-20).isActive = true
		let width3 = sizeField.widthAnchor.constraint(equalToConstant:52)
		width3.priority = .defaultHigh
		width3.isActive = true
		self.setupTextField(sizeField, size:NSFont.smallSystemFontSize, alignment:.right, alpha:0.5)
		
		self.view.needsLayout = true
	}
	
	
	override open func setup()
	{
		super.setup()
		
		// Listen to notifications to update the UI accordingly
		
		self.observers += NotificationCenter.default.publisher(for:AudioPreviewController.didStartPlayingObject, object:object).sink
		{
			[weak self] _ in self?.isPlaying = true
		}
		
		self.observers += NotificationCenter.default.publisher(for:AudioPreviewController.didStopPlayingObject, object:object).sink
		{
			[weak self] _ in self?.isPlaying = false
		}

		self.observers += self.view.publisher(for:\.effectiveAppearance).receive(on:RunLoop.main, options:nil).sink
		{
			[weak self] _ in self?.updateHighlight()
		}
		
		self.updateHighlight()

		// Configure text field truncation when text gets too long
		
		self.nameField?.lineBreakMode = .byTruncatingTail
		self.metadataField?.lineBreakMode = .byTruncatingTail

		// When reusing a cell, we also need to reset the isPlaying property

		self.isPlaying = false
	}
	

//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Drawing

	/// This function gets called when the Object or some metadata has changed and the cell needs to be redrawn.
	
	override open func redraw()
	{
		guard let object = object else { return }
		guard let metadata = object.metadata else { return }
		
		// Gather audio metadata
		
		let title = metadata[kMDItemTitle as String] as? String
		let authors = metadata[kMDItemAuthors as String] as? [String]
		let composer = metadata[kMDItemComposer as String] as? String
		let album = metadata[kMDItemAlbum as String] as? String
		let genre = metadata[kMDItemMusicalGenre as String] as? String
		let duration = metadata[kMDItemDurationSeconds as String] as? Double ?? 0.0
		let size = metadata[kMDItemFSSize as String] as? Int
		let kind = metadata[kMDItemKind as String] as? String
		let name = title ?? object.displayName
		
		// Build description string
		
		var description = ""
		
		if let artist = authors?.first ?? composer, !artist.isEmpty
		{
			description += artist
		}

		if let album = album, !album.isEmpty
		{
			if !description.isEmpty { description += ", " }
			description += album
		}

		if let genre = genre, !genre.isEmpty
		{
			if !description.isEmpty { description += ", " }
			description += genre
		}
		
		if let kind = kind, !kind.isEmpty
		{
			if !description.isEmpty { description += ", " }
			description += kind
		}

		// Update UI
		
		self.setIcon()
		self.nameField?.stringValue = name
		self.metadataField?.stringValue = description
		self.durationField?.stringValue = duration.shortTimecodeString()
		self.sizeField?.stringValue = size?.fileSizeDescription ?? ""
		
		if !object.isEnabled
		{
			self.nameField?.alphaValue = 0.5
			self.durationField?.alphaValue = 0.5
		}
		else
		{
			let enabled = object.isLocallyAvailable
			let alpha:CGFloat = enabled ? 1.0 : 0.5
			self.nameField?.alphaValue = alpha
			self.durationField?.alphaValue = alpha
		}
	}
	
	
	/// Sets a new tooltip on the cell
	
	override open func updateTooltip()
	{
		self.view.removeAllToolTips()
		self.view.subviews.forEach { $0.removeAllToolTips() }
		
		if let comment = self.object?.comment
		{
			self.view.toolTip = comment
			self.view.subviews.forEach { $0.toolTip = comment }
		}
	}
	
	
	/// Chooses an appropriate icon to display for the current state
	
	func setIcon()
	{
		if self.isPlaying
		{
			self.setPlaybackIcon()
		}
		else
		{
			self.setFileIcon()
		}
	}
	
	
	/// Displays the document file icon
	
	func setFileIcon()
	{
		self.showsWarningIcon = false
		
		if !object.isEnabled
		{
//			if object.isDRMProtected
//			{
				self.imageView?.image = NSImage(systemName:"exclamationmark.triangle.fill")
				self.imageView?.contentTintColor = .systemYellow
				self.imageView?.imageScaling = .scaleProportionallyUpOrDown
				self.showsWarningIcon = true
//			}
//			else if let url = self.object.previewItemURL, AudioFile.isIncompleteAppleLoop(at:url)
//			{
//				self.imageView?.image = NSImage(systemName:"exclamationmark.triangle.fill")
//				self.imageView?.contentTintColor = .systemYellow
//				self.imageView?.imageScaling = .scaleProportionallyUpOrDown
//				self.showsWarningIcon = true
//			}
		}
		else if object.isLocallyAvailable
		{
			if let thumbnail = object.thumbnailImage
			{
				let w = thumbnail.width
				let h = thumbnail.height
				let size = CGSize(width:w, height:h)
				self.imageView?.image = NSImage(cgImage:thumbnail, size:size)
				self.imageView?.contentTintColor = nil
			}
		}
		else if object.isDownloadable
		{
			if #available(macOS 11, *)
			{
				self.imageView?.image = NSImage(systemSymbolName:"icloud.and.arrow.down", accessibilityDescription:nil)
			}
			self.imageView?.contentTintColor = nil
		}
		else
		{
			if #available(macOS 11, *)
			{
				self.imageView?.image = NSImage(systemSymbolName:"exclamationmark.icloud", accessibilityDescription:nil)
			}
			self.imageView?.contentTintColor = nil
		}
	}
	
	
	/// Displays an icon that indicates audio playback
	
	func setPlaybackIcon()
	{
		if #available(macOS 11, *)
		{
			self.imageView?.image = NSImage(systemSymbolName:"speaker.wave.3.fill", accessibilityDescription:nil)
		}
	}
	
	
	/// Toggles between name field and rating control
	
	override open func showRatingControl(_ isInside:Bool)
	{
		let showRating = isInside || self.object.rating > 0
		self.textField?.isHidden = false
		self.ratingView?.isHidden = !showRating
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Selecting
	
	/// The current selection state

    override public var isSelected:Bool
    {
        didSet { self.updateHighlight() }
    }

	/// The current HighlightState
	
	override public var highlightState:NSCollectionViewItem.HighlightState
    {
        didSet { self.updateHighlight() }
    }
	
	// Whenever isSelected or highlightState have changed, then visual appearance of this cell is updated appropriately
	
    private func updateHighlight()
    {
        guard isViewLoaded else { return }

		let isHilited = self.isSelected	|| self.highlightState != .none
		let backgroundColor = isHilited ? NSColor.systemBlue : NSColor.clear
		let textColor = isHilited ? NSColor.white : NSColor.textColor
		var iconColor = self.view.effectiveAppearance.isDarkMode ? NSColor.white : NSColor.black
		if showsWarningIcon  { iconColor = .systemYellow }
		else if isHilited { iconColor = .white }
		
		self.view.layer?.backgroundColor = backgroundColor.cgColor
		self.imageView?.contentTintColor = iconColor
		self.nameField?.textColor = textColor
		self.metadataField?.textColor = textColor
		self.durationField?.textColor = textColor
		self.sizeField?.textColor = textColor
    }


//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Actions
	
	// Instead of QuickLook we use the AudioPreviewController - this is more intuitive for this use case
	
	override open func preview(with event:NSEvent?)
	{
		if let event = event, event.type == .keyDown
		{
			AudioPreviewController.shared.toggle()	// If spacebar key - so toggle playback
		}
		else
		{
			AudioPreviewController.shared.play()	// Otherwise assume double-click, so just play
		}
	}
}


//----------------------------------------------------------------------------------------------------------------------


// MARK: - Helpers
	
extension Int
{
	/// Creates a formatted file size description for the number of bytes
	
	var fileSizeDescription:String
	{
		let bytes = self
		let kilobytes = Double(bytes) / 1000
		let megabytes = kilobytes / 1000
		let gigabytes = megabytes / 1000
		let terabytes = gigabytes / 1000
		
		if bytes < 1000
		{
			return"\(bytes) bytes"
		}
		else if kilobytes < 1000
		{
			return "\(kilobytes.string(digits:1)) KB"
		}
		else if megabytes < 1000
		{
			return "\(megabytes.string(digits:1)) MB"
		}
		else if gigabytes < 1000
		{
			return "\(gigabytes.string(digits:1)) GB"
		}

		return "\(terabytes.string(digits:1)) TB"
	}
}


//----------------------------------------------------------------------------------------------------------------------


fileprivate extension Double
{
	/// Formats a Double number with the specified precision
	
	func string(for format:String = "#.#", digits:Int = 1) -> String
	{
		let formatter = NumberFormatter.forFloatingPoint(with:format, numberOfDigits:digits)
		return formatter.string(from:NSNumber(value:self)) ?? "0"
	}
}


//----------------------------------------------------------------------------------------------------------------------


#endif
