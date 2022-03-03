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


open class AudioObjectViewController : ObjectViewController
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
	
	// width 0 means full width of the view
	
	override class var width:CGFloat { 0 }
	
	// The cell is 46pt high
	
	override class var height:CGFloat { 46 }
	
	// No spacing between cells - to make it look like a NSTableView
	
	override class var spacing:CGFloat { 0 }

	// Set whenever playback status changes
	
	var isPlaying = false
	{
		didSet { redraw() }
	}
	
	
//----------------------------------------------------------------------------------------------------------------------


	// MARK: - Setup
	
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
		let name = title ?? object.name
		
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
		
		self.nameField?.alphaValue = object.isLocallyAvailable ? 1.0 : 0.5
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
		if object.isLocallyAvailable
		{
			if let thumbnail = object.thumbnailImage
			{
				let w = thumbnail.width
				let h = thumbnail.height
				let size = CGSize(width:w, height:h)
				self.imageView?.image = NSImage(cgImage:thumbnail, size:size)
			}
		}
		else if object.isDownloadable
		{
			if #available(macOS 11, *)
			{
				self.imageView?.image = NSImage(systemSymbolName:"icloud.and.arrow.down", accessibilityDescription:nil)
			}
		}
		else
		{
			if #available(macOS 11, *)
			{
				self.imageView?.image = NSImage(systemSymbolName:"exclamationmark.icloud", accessibilityDescription:nil)
			}
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
		if isHilited { iconColor = NSColor.white }

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
